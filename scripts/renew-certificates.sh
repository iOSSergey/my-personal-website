#!/bin/bash

# Script to manually renew Let's Encrypt certificates

# Read environment variables
if [ -f ./client_management_system.env ]; then
    export $(grep -v '^#' ./client_management_system.env | xargs)
fi

echo "Renewing SSL certificates for $SERVER_NAME..."

# Renew certificates using certbot
docker run --rm \
    -v certbot_www:/var/www/certbot \
    -v /etc/letsencrypt:/etc/letsencrypt \
    certbot/certbot \
    renew --quiet

# Copy renewed certificates to ssl directory
if [ -f "/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem" ]; then
    cp /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem ./ssl/
    cp /etc/letsencrypt/live/$SERVER_NAME/privkey.pem ./ssl/
    echo "Certificates copied successfully!"
else
    echo "Warning: Certificates not found at expected location"
fi

# Reload nginx configuration
docker exec nginx nginx -s reload

echo "SSL certificates renewed and nginx reloaded!"