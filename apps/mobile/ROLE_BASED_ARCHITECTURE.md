# Single App - Multiple Roles Architecture

## Концепция
Одно Flutter-приложение с динамической навигацией в зависимости от роли пользователя.

## User Roles

```dart
enum UserRole {
  driver,      // Водитель - доставка
  sales,       // Sales manager - регистрация клиентов, заказы
  manager,     // Менеджер - просмотр статистики, управление
  admin,       // Админ - полный доступ
}
```

## Entry Flow

```
[Login Screen]
     ↓
[Определение роли из JWT токена или API]
     ↓
[RoleRouter] → Создает правильный набор экранов
     ↓
┌─────────────────────────────────────────────────────────────┐
│ Driver App                      Sales App                   │
│ ┌──────────────┐                ┌──────────────┐           │
│ │ 📍 Route     │                │ 👥 Clients   │           │
│ │ 📦 Orders    │                │ ➕ New Order │           │
│ │ 👤 Profile   │                │ 📊 Stats     │           │
│ └──────────────┘                └──────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Technical Implementation

### Role-Based Navigation
```dart
class RoleRouter extends StatelessWidget {
  final UserRole role;
  
  @override
  Widget build(BuildContext context) {
    return switch (role) {
      UserRole.driver => DriverNavigation(),
      UserRole.sales => SalesNavigation(),
      UserRole.manager => ManagerNavigation(),
      UserRole.admin => AdminNavigation(), // Can switch between modes
    };
  }
}
```

### Shared Components
- Авторизация
- Профиль пользователя
- Настройки
- Оффлайн синхронизация

### Role-Specific Features

#### Driver
- Route screen with map
- Delivery list
- Photo/signature capture
- GPS tracking

#### Sales
- Client catalog (offline)
- Client registration with OTP
- Quick order creation
- Offline mode critical

#### Manager
- Dashboard with stats
- Orders overview
- Driver tracking
- Reports

## Pros & Cons

### ✅ Pros
- Один кодбейс вместо 3
- Общая логика (auth, sync, notifications)
- Быстрее разрабатывать
- Легче поддерживать
- Пользователь может иметь несколько ролей

### ❌ Cons
- Размер приложения больше
- Сложнее тестировать все роли
- Нужна защита от случайного доступа к чужим фичам
