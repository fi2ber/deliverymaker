# DeliveryMaker

Система управления доставкой с мультитенантностью.

## Архитектура

- **API**: NestJS (Node.js) - REST API сервер
- **Web**: Next.js - Frontend приложение
- **TMA**: Telegram Mini App
- **Mobile**: Flutter - мобильное приложение для курьеров
- **Database**: PostgreSQL
- **Cache**: Redis
- **Proxy**: Nginx

## Быстрый старт

### Локальная разработка

```bash
# Установка зависимостей
npm install

# Запуск всех сервисов
docker-compose up -d

# Или запуск API отдельно
npm run dev -w apps/api

# Запуск Web
npm run dev -w apps/web
```

## Деплой на сервер

### 1. Настройка сервера

```bash
# На сервере выполните:
curl -fsSL https://raw.githubusercontent.com/fi2ber/deliverymaker/main/deployment/setup-server.sh | bash
```

Или вручную:

```bash
# Клонирование репозитория
git clone https://github.com/fi2ber/deliverymaker.git /opt/deliverymaker
cd /opt/deliverymaker

# Настройка окружения
cp .env.example .env
# Отредактируйте .env файл

# Запуск
docker-compose up -d --build
```

### 2. Настройка DNS

Настройте A-записи домена:
- `deliverymaker.uz` → IP сервера
- `api.deliverymaker.uz` → IP сервера
- `*.deliverymaker.uz` → IP сервера

### 3. SSL сертификаты (Let's Encrypt)

```bash
cd /opt/deliverymaker
./deployment/setup-ssl.sh
```

### 4. Автоматический деплой (CI/CD)

Добавьте Secrets в GitHub репозиторий:
- `SSH_PRIVATE_KEY` - приватный SSH ключ
- `SERVER_HOST` - IP или домен сервера
- `SERVER_USER` - пользователь на сервере

При каждом push в `main` ветку будет автоматический деплой.

## Структура проекта

```
.
├── apps/
│   ├── api/           # Backend API (NestJS)
│   ├── web/           # Frontend (Next.js)
│   ├── tma/           # Telegram Mini App
│   └── mobile/        # Flutter приложение
├── packages/          # Общие пакеты
├── deployment/        # Скрипты деплоя
└── docker-compose.yml
```

## Команды

```bash
# Сборка
docker-compose build

# Перезапуск
docker-compose restart

# Логи
docker-compose logs -f
docker-compose logs -f api

# База данных
docker-compose exec postgres psql -U postgres -d delivery_maker
```

## Лицензия

Proprietary
