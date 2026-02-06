#!/bin/bash

# SSL Setup with Certbot

echo "🔒 Setting up SSL certificates..."

# Install Certbot
echo "📦 Installing Certbot..."
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificates
DOMAIN="deliverymaker.uz"
API_DOMAIN="api.deliverymaker.uz"

echo "📜 Obtaining certificates for $DOMAIN and $API_DOMAIN..."
sudo certbot certonly --standalone -d $DOMAIN -d $API_DOMAIN --agree-tos -n --email admin@$DOMAIN

# Update nginx config for SSL
cat > /opt/deliverymaker/deployment/nginx/nginx-ssl.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    # Backend API Upstream
    upstream backend_api {
        server api:3000;
    }

    # Frontend Upstream
    upstream web_client {
        server web:3000;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name api.deliverymaker.uz deliverymaker.uz *.deliverymaker.uz;
        return 301 https://$host$request_uri;
    }

    # API Server (HTTPS)
    server {
        listen 443 ssl http2;
        server_name api.deliverymaker.uz;

        ssl_certificate /etc/letsencrypt/live/deliverymaker.uz/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/deliverymaker.uz/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://backend_api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Tenant-Context $host;
        }
    }

    # Web Client (HTTPS)
    server {
        listen 443 ssl http2;
        server_name deliverymaker.uz *.deliverymaker.uz;

        ssl_certificate /etc/letsencrypt/live/deliverymaker.uz/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/deliverymaker.uz/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://web_client;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Update docker-compose to use SSL config and mount certs
sed -i 's|./deployment/nginx/nginx.conf|./deployment/nginx/nginx-ssl.conf|' /opt/deliverymaker/docker-compose.yml
sed -i 's|#- "443:443"|- "443:443"|' /opt/deliverymaker/docker-compose.yml

# Add SSL certificate volume if not present
if ! grep -q "letsencrypt" /opt/deliverymaker/docker-compose.yml; then
    sed -i '/volumes:/a\      - /etc/letsencrypt:/etc/letsencrypt:ro' /opt/deliverymaker/docker-compose.yml
fi

# Reload nginx
cd /opt/deliverymaker
docker-compose exec nginx nginx -s reload

echo "✅ SSL setup complete!"
echo "🔄 Restarting services..."
docker-compose restart

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'docker-compose -f /opt/deliverymaker/docker-compose.yml exec nginx nginx -s reload'" | sudo crontab -

echo "📅 Auto-renewal cron job added"
