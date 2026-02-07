# Production Deployment Guide

## 🚀 Quick Start

### Prerequisites

- Server with Ubuntu 20.04/22.04 (4GB+ RAM, 2+ CPU cores, 40GB SSD)
- Domain name (e.g., deliverymaker.uz)
- Docker and Docker Compose installed

### Step 1: Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install certbot for SSL
sudo apt install certbot -y
```

### Step 2: Clone and Configure

```bash
# Clone repository
git clone https://github.com/yourusername/deliverymaker.git
cd deliverymaker

# Copy environment file
cp deployment/.env.example deployment/.env

# Edit with your settings
nano deployment/.env
```

### Step 3: SSL Certificates

```bash
# Obtain SSL certificate
sudo certbot certonly --standalone -d deliverymaker.uz -d api.deliverymaker.uz -d admin.deliverymaker.uz

# Copy certificates
cp -r /etc/letsencrypt deployment/nginx/ssl/
```

### Step 4: Deploy

```bash
cd deployment
chmod +x deploy.sh
./deploy.sh production
```

## 📋 Services

After deployment, the following services will be available:

| Service | URL | Description |
|---------|-----|-------------|
| API | https://api.deliverymaker.uz | Backend API |
| Web Admin | https://admin.deliverymaker.uz | Warehouse & Admin UI |
| OSRM | http://localhost:5000 | Maps & Routing |

## 🔧 Management Commands

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f api
docker-compose logs -f web

# Restart service
docker-compose restart api

# Update (pull new images and restart)
docker-compose pull
docker-compose up -d

# Database backup
docker-compose exec postgres pg_dump -U deliverymaker deliverymaker > backup_$(date +%Y%m%d).sql

# Database restore
cat backup.sql | docker-compose exec -T postgres psql -U deliverymaker
```

## 🗺️ OSRM First Setup

**Important:** OSRM downloads and processes Uzbekistan map data on first run. This takes **30-60 minutes**.

Monitor progress:
```bash
docker-compose logs -f osrm
```

You'll see:
```
[info] Downloading Uzbekistan map data...
[info] Processing map data...
[info] Starting OSRM server...
```

## 📱 Firebase Setup (Push Notifications)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project "DeliveryMaker"
3. Add Android and iOS apps
4. Go to Project Settings > Cloud Messaging
5. Copy "Server key" to `FCM_SERVER_KEY` in .env

## 🤖 Telegram Bot Setup

1. Message [@BotFather](https://t.me/botfather)
2. Create new bot with `/newbot`
3. Copy token to `TELEGRAM_BOT_TOKEN` in .env
4. Set webhook:
```bash
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -d "url=https://api.deliverymaker.uz/webhooks/telegram/<TENANT_ID>"
```

## 🔒 Security Checklist

- [ ] Change default database password
- [ ] Generate strong JWT_SECRET (32+ chars)
- [ ] Enable firewall (ufw)
- [ ] Configure fail2ban
- [ ] Set up automated backups
- [ ] Enable CloudFlare (optional)

## 🚨 Troubleshooting

### OSRM not responding
```bash
# Check OSRM logs
docker-compose logs osrm

# If map data is missing, manually download:
cd osrm_data
wget https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf
cd ..
docker-compose restart osrm
```

### Database connection failed
```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready

# Reset database (WARNING: data loss!)
docker-compose down -v
docker-compose up -d postgres
```

### SSL certificate expired
```bash
# Renew
sudo certbot renew

# Copy new certs
cp -r /etc/letsencrypt deployment/nginx/ssl/
docker-compose restart nginx
```

## 💰 Cost Estimation

| Component | Provider | Monthly Cost |
|-----------|----------|--------------|
| VPS (4GB, 2 CPU) | Hetzner | €8-12 |
| Domain | Any | €10/year |
| SSL (Let's Encrypt) | Free | €0 |
| Firebase | Free tier | €0 |
| **Total** | | **~€10-15/month** |

## 📞 Support

- Telegram: @deliverymaker_support
- Email: support@deliverymaker.uz
