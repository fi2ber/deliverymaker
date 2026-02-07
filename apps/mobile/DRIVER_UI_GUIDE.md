# Driver UI - Руководство

## Что реализовано

### 📱 Экран маршрута (`RouteScreen`)

```
┌─────────────────────────────────────────┐
│  ←  Маршрут доставки        [прогресс] │  ← Glass header
├─────────────────────────────────────────┤
│                                         │
│         [КАРТА OpenStreetMap]           │  ← flutter_map
│                                         │
│    ●───●────●────●                      │  ← Маршрут + точки
│         🚚                              │  ← Текущее положение
│                                         │
├─────────────────────────────────────────┤
│  ⬆                                     │  ← Drag handle
│  Маршрут доставки        [3/5] ⬤⬤⬤⬤⬤ │  ← Progress bar
│  🚗 12.5 км    ⏱ 45 мин    📦 2 осталось│  ← Stats
├─────────────────────────────────────────┤
│  ①  Анвар Рахимов            [Следующая]│
│     ул. Амира Темура, 45              │
│     💬 Домофон не работает              │
│  ─────────────────────────────────────  │
│  📞 Позвонить  🧭 Маршрут  ✅ Доставлено│  ← Action buttons
├─────────────────────────────────────────┤
│  ②  Гулноза Каримова                    │
│     ул. Навои, 128...                   │
└─────────────────────────────────────────┘
```

### 🎨 iOS 18 Design System

**Цвета:**
- `systemBlue` #007AFF - Основной акцент
- `systemGreen` #34C759 - Успех/доставлено
- `systemOrange` #FF9500 - Предупреждения
- `systemRed` #FF3B30 - Ошибки

**Эффекты:**
- Glassmorphism (blur + opacity)
- Spring animations (curves.spring)
- Haptic feedback (light/medium/heavy)

**Типографика:**
- Шрифт: Manrope (400, 500, 600, 700, 800)
- Title 1: 28px Bold
- Body: 17px Regular
- Caption: 13px Secondary

### 🗺️ Карта (OpenStreetMap)

**Возможности:**
- Отображение маршрута (полилиния)
- Маркеры точек доставки с номерами
- Пульсирующий маркер текущего положения
- Зум и перемещение
- Автоматический фит границ

**Управление:**
- Кнопка "Моё местоположение" (recenter)
- Кнопки зума (+/-)
- Свайп карты

### 📋 Список доставок

**Фичи:**
- Draggable bottom sheet (3 позиции)
- Progress bar выполнения
- Карточки с инфо клиента
- Комментарии (жёлтый бейдж)
- Быстрые действия (позвонить, маршрут, доставлено)

### ✅ Подтверждение доставки

**Шаги:**
1. Сделать фото (обязательно)
2. Добавить комментарий (опционально)
3. Нажать "Подтвердить"

**UI:**
- Крупная кнопка камеры
- Превью фото с возможностью переснять
- Текстовое поле для комментария
- Индикатор загрузки

## Архитектура кода

```
lib/
├── core/
│   └── theme/
│       └── ios_theme.dart          # iOS 18 design system
├── services/
│   └── map_service.dart            # OSRM routing
├── features/
│   └── driver/
│       ├── bloc/
│       │   └── route_bloc.dart     # State management
│       ├── screens/
│       │   └── route_screen.dart   # Main screen
│       └── widgets/
│           ├── route_map.dart      # Map widget
│           ├── stops_list.dart     # Bottom sheet list
│           └── delivery_completion_sheet.dart  # Photo + confirm
```

## Использование

### 1. Добавить зависимости

```bash
cd apps/mobile
flutter pub add flutter_map flutter_map_animations latlong2 http image_picker
```

### 2. Обновить AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### 3. Запустить

```bash
flutter run
```

## Настройка OSRM сервера

См. [MAPS_SETUP.md](./MAPS_SETUP.md)

Кратко:
1. Сервер с Docker
2. Скачать карты Узбекистана
3. Запустить OSRM контейнер
4. Прописать URL в `map_service.dart`

## Кастомизация

### Изменить цвета

```dart
// ios_theme.dart
static const Color systemBlue = Color(0xFF007AFF);  // Ваш цвет
```

### Добавить новые действия

```dart
// stops_list.dart
_ActionButton(
  icon: Icons.chat_bubble_outline,
  label: 'Написать',
  onTap: () => _openChat(stop),
)
```

### Изменить стиль карты

```dart
// route_map.dart
TileLayer(
  urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  // или другой tile provider
)
```

## Следующие шаги

1. **Интеграция с backend**
   - Заменить `_mockStops` на загрузку из API/Isar
   - Добавить синхронизацию completed доставок

2. **Геолокация**
   - Добавить `geolocator` пакет
   - Трекать реальное положение водителя

3. **Push уведомления**
   - Firebase Cloud Messaging
   - Уведомления о новых назначениях

4. **Оффлайн режим**
   - Кэширование карт (flutter_map tile cache)
   - Очередь синхронизации через Isar
