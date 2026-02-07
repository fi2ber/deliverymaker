# Offline-First Architecture Guide

## Концепция

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                              │
│                                                                  │
│   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐    │
│   │   UI Layer  │◄────►│   BLoC      │◄────►│ Repository  │    │
│   │             │      │             │      │             │    │
│   └─────────────┘      └─────────────┘      └──────┬──────┘    │
│                                                     │            │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                  Data Layer                             │   │
│   │                                                          │   │
│   │   ┌─────────────┐      ┌─────────────┐                  │   │
│   │   │    Isar     │◄────►│ Sync Queue  │                  │   │
│   │   │    (DB)     │      │             │                  │   │
│   │   └─────────────┘      └──────┬──────┘                  │   │
│   │                                │                         │   │
│   │   ┌─────────────┐      ┌──────┴──────┐                  │   │
│   │   │  Sync Meta  │      │ Sync Engine │                  │   │
│   │   │             │      │             │                  │   │
│   │   └─────────────┘      └──────┬──────┘                  │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                   │                              │
│                          Online?  │                              │
│                              ┌────┴────┐                        │
│                              ▼         ▼                        │
│                         [SYNC]    [QUEUE]                       │
│                              │         │                        │
└──────────────────────────────┼─────────┼────────────────────────┘
                               │         │
                    ┌──────────┴─────────┴──────────┐
                    │         NESTJS API            │
                    │      ┌──────────────┐         │
                    │      │  PostgreSQL  │         │
                    │      └──────────────┘         │
                    └─────────────────────────────────┘
```

## Flow

### 1. Чтение данных (всегда локально)
```dart
// UI запрашивает данные
final orders = await orderRepository.getDriverOrders(driverId);

// Репозиторий читает из Isar (мгновенно)
return await db.orders.where().findAll();

// Фоном запускается sync (если онлайн)
_syncEngine.sync();
```

### 2. Запись данных (всегда локально сначала)
```dart
// Пользователь отмечает доставку
await orderRepository.markAsDelivered(orderId, proof);

// Репозиторий:
// 1. Сохраняет в Isar
// 2. Добавляет в SyncQueue
// 3. Возвращает управление

// Фоном (если онлайн):
// 4. SyncEngine отправляет на сервер
// 5. Обновляет статус в Isar
```

### 3. Sync Queue

```dart
class SyncQueueItem {
  entityType: 'order',        // Тип сущности
  localId: '123',            // Локальный ID
  serverId: null,            // Серверный ID (после sync)
  operation: 'deliver',      // create/update/delete
  payload: '{"status": "delivered"...}',
  priority: 1,               // 1=high, 2=normal, 3=low
  retryCount: 0,             // Попытки отправки
}
```

### 4. Обработка ошибок

**Сценарий: Нет интернета**
```
1. Пользователь отмечает доставку
2. Данные сохранены в Isar
3. SyncQueueItem создан
4. Попытка отправки → Fail
5. RetryCount = 1, LastError = "No connection"
6. Ждём появления сети
7. Автоматическая повторная попытка
```

**Сценарий: Конфликт данных**
```
1. Водитель отметил доставку (офлайн)
2. Менеджер отменил заказ (онлайн)
3. Водитель подключился к сети
4. Sync отправляет "delivered"
5. Сервер возвращает 409 Conflict
6. Разрешение: Server Wins (приоритет сервера)
7. Локальные данные обновлены с сервера
```

## Entities

### OrderEntity
```dart
@Collection()
class OrderEntity {
  Id id = Isar.autoIncrement;     // Локальный ID
  String? serverId;               // Серверный ID
  String status;                  // Статус
  SyncStatus? syncStatus;         // Статус синхронизации
}
```

### SyncStatus (Embedded)
```dart
@embedded
class SyncStatus {
  bool isSynced = false;          // Синхронизирован?
  bool hasPendingChanges = true;  // Есть неотправленные изменения?
  bool hasConflict = false;       // Конфликт?
}
```

## API

### SyncEngine
```dart
// Инициализация
await SyncEngine().initialize();

// Ручной запуск синхронизации
final result = await SyncEngine().sync();

// Подписка на статус
SyncEngine().syncStatus.listen((status) {
  print('Sync: $status');
});
```

### OrderRepository
```dart
// Получение (всегда из локальной БД)
final orders = await orderRepository.getDriverOrders(driverId);

// Запись (локально + в очередь)
await orderRepository.markAsDelivered(orderId, proof);

// Прослушивание изменений (реактивно)
orderRepository.watchOrders(driverId).listen((orders) {
  updateUI(orders);
});
```

## UI Integration

### Sync Status Bar
```dart
BlocBuilder<RouteBloc, RouteState>(
  builder: (context, state) {
    return SyncStatusBar(
      status: state.syncStatus,
      isOnline: state.isOnline,
      onTap: () => context.read<RouteBloc>().add(RefreshRoute()),
    );
  },
)
```

### Offline Indicator
```dart
if (!state.isOnline) {
  return Banner(
    message: 'ОФФЛАЙН РЕЖИМ',
    location: BannerLocation.topEnd,
    color: Colors.orange,
    child: MyWidget(),
  );
}
```

## Testing Offline Mode

### 1. Включите режим полета
- Все данные сохраняются локально
- SyncQueue накапливается
- UI работает нормально

### 2. Отключите режим полета
- Автоматическая синхронизация
- Очередь отправляется на сервер
- Обновляются статусы

### 3. Проверьте конфликты
- Измените данные на сервере
- Измените локально (офлайн)
- Включите сеть
- Убедитесь что применился Server Wins

## Performance

### Isar Benchmarks (на устройстве)
- Чтение 10,000 записей: ~10ms
- Запись 1,000 записей: ~50ms
- Query с фильтром: ~5ms

### Sync Strategy
- Sync каждые 2 минуты (фон)
- Мгновенный sync при важных действиях
- Batch upload (не по одной)
- Retry с exponential backoff

## Storage Limits

### Isar
- Теоретический лимит: 16TB
- Практический: ограничен диском устройства
- Рекомендуемый размер: < 100MB

### Cleanup
```dart
// Автоматическая очистка старых заказов (30+ дней)
await orderRepository.cleanupOldOrders();

// Очистка фото после upload
await photoRepository.cleanupUploadedPhotos();
```

## Troubleshooting

### Синхронизация не работает
```bash
# Проверьте connectivity
final isOnline = await ConnectivityService().checkNow();

# Проверьте queue
final queue = await db.syncQueue.where().findAll();
print('Pending items: ${queue.length}');

# Форсированный sync
await SyncEngine().sync();
```

### Конфликты данных
```dart
// Посмотрите конфликты
final conflicts = await db.orders
  .filter()
  .syncStatus((q) => q.hasConflictEqualTo(true))
  .findAll();
```

### Большой размер БД
```bash
# Используйте Isar Inspector
flutter pub run isar_inspector

# Посмотрите размер коллекций
# Оптимизируйте cleanup
```
