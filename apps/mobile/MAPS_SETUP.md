# Настройка карт и маршрутов (OSRM)

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                              │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │ flutter_map  │        │ OSRM Service │                  │
│  │ (OSM tiles)  │        │ (routing)    │                  │
│  └──────────────┘        └──────────────┘                  │
└────────────────────────────────┬────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │      Ваш сервер         │
                    │  ┌──────────────────┐   │
                    │  │ OSRM Backend     │   │
                    │  │ (Docker)         │   │
                    │  └──────────────────┘   │
                    └─────────────────────────┘
```

## Вариант 1: Собственный сервер OSRM (Рекомендуется)

### Шаг 1: Подготовка сервера

Минимальные требования:
- CPU: 2+ cores
- RAM: 4GB (8GB для Узбекистана)
- Disk: 20GB SSD
- OS: Ubuntu 20.04/22.04

### Шаг 2: Установка Docker

```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker
```

### Шаг 3: Загрузка карт Узбекистана

```bash
# Создаем директорию
mkdir -p ~/osrm-data
cd ~/osrm-data

# Скачиваем карты Узбекистана (Geofabrik)
wget https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf

# Или для всей Центральной Азии (если нужно)
# wget https://download.geofabrik.de/asia/central-asia-latest.osm.pbf
```

### Шаг 4: Запуск OSRM

```bash
# Предобработка (первый запуск, занимает 10-30 минут)
docker run -t -v $(pwd):/data osrm/osrm-backend:latest \
  osrm-extract -p /opt/car.lua /data/uzbekistan-latest.osm.pbf

docker run -t -v $(pwd):/data osrm/osrm-backend:latest \
  osrm-partition /data/uzbekistan-latest.osrm

docker run -t -v $(pwd):/data osrm/osrm-backend:latest \
  osrm-customize /data/uzbekistan-latest.osrm

# Запуск сервера
docker run -d --name osrm \
  -p 5000:5000 \
  -v $(pwd):/data \
  osrm/osrm-backend:latest \
  osrm-routed --algorithm mld /data/uzbekistan-latest.osrm
```

### Шаг 5: Проверка

```bash
# Тест маршрута (из терминала сервера)
curl "http://localhost:5000/route/v1/driving/69.2401,41.2995;69.2797,41.3111?overview=full"

# Должен вернуть JSON с маршрутом
```

### Шаг 6: Nginx + SSL (для продакшена)

```bash
# Установка Nginx
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx

# Конфигурация /etc/nginx/sites-available/osrm
server {
    listen 80;
    server_name osrm.yourdomain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # CORS для Flutter app
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    }
}

# Активация
sudo ln -s /etc/nginx/sites-available/osrm /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# SSL
sudo certbot --nginx -d osrm.yourdomain.com
```

## Вариант 2: Docker Compose (Проще)

Создайте `docker-compose.yml`:

```yaml
version: '3.8'

services:
  osrm:
    image: osrm/osrm-backend:latest
    container_name: osrm
    ports:
      - "5000:5000"
    volumes:
      - ./data:/data
    command: >
      bash -c "
        osrm-extract -p /opt/car.lua /data/uzbekistan-latest.osm.pbf &&
        osrm-partition /data/uzbekistan-latest.osrm &&
        osrm-customize /data/uzbekistan-latest.osrm &&
        osrm-routed --algorithm mld /data/uzbekistan-latest.osrm
      "
    restart: unless-stopped
```

Запуск:
```bash
# Скачать карту
mkdir -p data
cd data
wget https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf
cd ..

# Первый запуск (долгий)
docker-compose up

# Последующие запуски (быстрые)
docker-compose up -d
```

## Настройка Flutter

### 1. Обновите URL в коде

```dart
// lib/services/map_service.dart
class OSRMService {
  // Замените на ваш сервер
  static const String _baseUrl = 'https://osrm.yourdomain.com';
  // или 'http://your-server-ip:5000' для теста
}
```

### 2. Android разрешения

`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 3. iOS разрешения

`ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Для отображения вашего местоположения на карте</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Для навигации по маршруту доставки</string>
```

## Тестирование

```dart
// Пример использования
final route = await OSRMService.getRoute([
  LatLng(41.2995, 69.2401), // Ташкент центр
  LatLng(41.3111, 69.2797), // Другая точка
]);

print('Расстояние: ${route.formattedDistance}'); // "12.5 км"
print('Время: ${route.formattedDuration}');      // "25 мин"
```

## Обновление карт

Карты нужно обновлять раз в месяц:

```bash
cd ~/osrm-data

# Остановка контейнера
docker stop osrm
docker rm osrm

# Удаление старых файлов
rm uzbekistan-latest.osrm*

# Скачивание новых
wget https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf

# Пересборка и запуск
# (см. Шаг 4 выше)
```

## Стоимость

| Компонент | Стоимость |
|-----------|-----------|
| Сервер (2 CPU, 4GB) | ~$10-20/мес (Hetzner, DigitalOcean) |
| Трафик | ~$5-10/мес |
| **Итого** | **~$15-30/мес** |

Сравнение с Яндексом: **в 10 раз дешевле** при 1000+ запросов/день.

## Troubleshooting

### Проблема: Медленная маршрутизация
Решение: Увеличьте RAM сервера до 8GB или используйте `osrm-contract` вместо `osrm-partition` для маленьких регионов.

### Проблема: Нет маршрутов в регионах
Решение: Убедитесь что карты содержат нужные дороги. Проверьте на openstreetmap.org.

### Проблема: CORS ошибки
Решение: Добавьте CORS заголовки в nginx (см. Шаг 6).
