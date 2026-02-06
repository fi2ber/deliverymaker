#!/bin/bash

# DeliveryMaker Server Setup Script
# Run this on your Ubuntu/Debian server

set -e

echo "🚀 Setting up DeliveryMaker server..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker if not exists
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not exists
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create app directory
APP_DIR="/opt/deliverymaker"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Clone repository if not exists
if [ ! -d "$APP_DIR/.git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/fi2ber/deliverymaker.git $APP_DIR
fi

cd $APP_DIR

# Create environment file if not exists
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your actual configuration!"
    nano .env
fi

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose up -d --build

echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Configure your DNS: api.deliverymaker.uz -> $(curl -s ifconfig.me)"
echo "   2. Configure your DNS: deliverymaker.uz -> $(curl -s ifconfig.me)"
echo "   3. Setup SSL with: ./deployment/setup-ssl.sh"
echo ""
echo "📊 Check status: docker-compose ps"
echo "📜 View logs: docker-compose logs -f"
