#!/bin/bash

# DeliveryMaker Production Deployment Script
# Usage: ./deploy.sh [environment]
# Environments: production, staging

set -e

ENVIRONMENT=${1:-production}
echo "🚀 Deploying to $ENVIRONMENT..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Load environment variables
# Load environment variables
set -a
[ -f .env ] && . .env
set +a

echo -e "${YELLOW}📦 Step 1: Building images...${NC}"
docker-compose -f docker-compose.yml build --no-cache

echo -e "${YELLOW}🗄️  Step 2: Starting database and Redis...${NC}"
docker-compose up -d postgres redis

# Wait for database
echo "⏳ Waiting for database..."
sleep 10

# Run migrations
echo -e "${YELLOW}🔄 Step 3: Running database migrations...${NC}"
docker-compose run --rm api npm run migration:run

# Download OSRM data if not exists
echo -e "${YELLOW}🗺️  Step 4: Checking OSRM data...${NC}"
if [ ! -f "osrm_data/uzbekistan-latest.osrm" ]; then
    echo "⏳ OSRM data not found. Will be downloaded on first start..."
    echo "⚠️  Warning: This may take 30-60 minutes!"
fi

echo -e "${YELLOW}🚀 Step 5: Starting all services...${NC}"
docker-compose up -d

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 30

# Health checks
echo -e "${YELLOW}🏥 Step 6: Health checks...${NC}"

check_service() {
    local name=$1
    local url=$2
    
    if curl -s "$url" > /dev/null; then
        echo -e "${GREEN}✅ $name is healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ $name is not responding${NC}"
        return 1
    fi
}

check_service "API" "http://localhost:3000/health"
check_service "Web" "http://localhost:3001"
check_service "OSRM" "http://localhost:5000/route/v1/driving/69.2401,41.2995;69.2797,41.3111"

echo ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo "📋 Services:"
echo "  • API: http://localhost:3000"
echo "  • Web Admin: http://localhost:3001"
echo "  • OSRM: http://localhost:5000"
echo ""
echo "📊 Monitor with:"
echo "  docker-compose logs -f"
echo ""
echo "🔧 Useful commands:"
echo "  docker-compose ps          # Check status"
echo "  docker-compose logs api    # API logs"
echo "  docker-compose down        # Stop all"
echo "  docker-compose down -v     # Stop and remove volumes"
