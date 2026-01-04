#!/bin/bash

# Script to manually renew Let's Encrypt certificates

echo "Renewing SSL certificates..."

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
fi

# Reload nginx configuration
docker exec nginx nginx -s reload

echo "SSL certificates renewed and nginx reloaded!"