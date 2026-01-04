#!/bin/bash

# Script to initialize Let's Encrypt certificates for nginx

# Read environment variables
if [ -f ./client_management_system.env ]; then
    export $(grep -v '^#' ./client_management_system.env | xargs)
fi

# Check if certificates already exist
if [ -f "/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem" ]; then
    echo "Certificate already exists for $SERVER_NAME"
    exit 0
fi

echo "Creating certificate for $SERVER_NAME..."

# Create temporary nginx config for initial certificate creation
cat > /tmp/nginx-init.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $SERVER_NAME;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 200 'OK';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start temporary nginx with simple config
docker run --rm -d \
    --name nginx-temp \
    -p 80:80 \
    -v $(pwd)/ssl:/etc/nginx/ssl \
    -v certbot_www:/var/www/certbot \
    -v /tmp/nginx-init.conf:/etc/nginx/nginx.conf \
    nginx:latest

# Wait for nginx to start
sleep 5

# Create certificate
docker run --rm \
    -v certbot_www:/var/www/certbot \
    -v /etc/letsencrypt:/etc/letsencrypt \
    certbot/certbot \
    certonly --webroot --webroot-path=/var/www/certbot \
    --email admin@$SERVER_NAME \
    --agree-tos \
    --no-eff-email \
    -d $SERVER_NAME \
    -d www.$SERVER_NAME

# Stop temporary nginx
docker stop nginx-temp

# Copy certificates to ssl directory
if [ -f "/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem" ]; then
    cp /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem ./ssl/
    cp /etc/letsencrypt/live/$SERVER_NAME/privkey.pem ./ssl/
    echo "Certificates created and copied successfully!"
else
    echo "Failed to create certificates"
    exit 1
fi