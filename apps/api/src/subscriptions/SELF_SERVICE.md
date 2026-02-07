# Self-Service Subscription Flow

## Overview
Поток самообслуживания для клиентов через Telegram Mini App (TMA). Клиенты могут самостоятельно регистрироваться, просматривать продукты и оформлять подписки без участия менеджера.

## Flow Architecture

```
1. QR/Ссылка → Telegram Bot
2. Bot отправляет WebApp кнопку с start_param=tenant_id
3. TMA открывается, извлекает initData
4. Авто-регистрация клиента через POST /customers/self-register
5. Клиент просматривает комбо-подписки
6. Выбор подписки → POST /subscriptions/self-service
7. Telegram Invoice создаётся через POST /integrations/telegram/invoice
8. Клиент оплачивает через Telegram Payments
9. Webhook активирует подписку
10. Подтверждение отправляется в чат
```

## API Endpoints

### Customer Self-Registration
```http
POST /customers/self-register
Content-Type: application/json

{
  "telegramId": 123456789,
  "firstName": "Иван",
  "lastName": "Иванов",
  "username": "ivan_user",
  "source": "telegram_bot",
  "startParam": "tenant_abc123"
}
```

### Create Self-Service Subscription
```http
POST /subscriptions/self-service
Content-Type: application/json

{
  "comboProductId": "uuid",
  "customerId": "uuid",
  "deliveryAddress": {
    "address": "ул. Примерная, 123",
    "phone": "+998901234567",
    "comment": "Домофон 456"
  },
  "paymentProvider": "telegram",
  "totalAmount": 165000
}
```

### Create Telegram Invoice
```http
POST /integrations/telegram/invoice
Content-Type: application/json

{
  "subscriptionId": "uuid",
  "title": "Семейный набор",
  "description": "Доставка продуктов — 8 недель",
  "amount": 16500000,
  "payload": "{\"subscriptionId\":\"uuid\"}"
}
```

### Telegram Payment Webhook
```http
POST /webhooks/telegram/:tenantId
Content-Type: application/json

{
  "message": {
    "successful_payment": {
      "currency": "UZS",
      "total_amount": 16500000,
      "invoice_payload": "...",
      "telegram_payment_charge_id": "..."
    }
  }
}
```

## Entities

### Customer
- `telegramId` - уникальный ID Telegram
- `telegramUsername` - @username
- `telegramChatId` - ID чата для уведомлений
- `source` - источник регистрации
- `isPhoneVerified` - статус верификации

### Subscription
- `customerId` - связь с Customer
- `status` - PENDING → ACTIVE после оплаты
- `paymentStatus` - pending/paid/failed
- `telegramPaymentChargeId` - ID платежа в Telegram
- `orderCode` - человекочитаемый номер заказа

## TMA Integration

### Init Data
```typescript
const tg = window.Telegram.WebApp;
const user = tg.initDataUnsafe.user;
const tenantId = tg.initDataUnsafe.start_param;
```

### Hooks
- `useCustomer()` - управление регистрацией клиента
- `useSubscription()` - создание подписок и оплата

### Components
- `WelcomeScreen` - экран приветствия для новых клиентов
- `SubscriptionBuilder` - форма оформления подписки
- `ProductCard` / `ComboCard` - карточки продуктов

## Security
- Все запросы содержат `X-Telegram-Init-Data` для валидации
- Backend проверяет HMAC-SHA256 подпись Telegram
- JWT токены для авторизации последующих запросов

## Multi-tenancy
- `start_param` содержит tenant_id
- Каждый тенант имеет свой Telegram Bot
- Webhook URL: `/webhooks/telegram/:tenantId`
