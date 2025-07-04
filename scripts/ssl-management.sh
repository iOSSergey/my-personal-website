#!/bin/bash

# SSL Certificate Management Script for Let's Encrypt
# This script handles initial certificate generation and renewal

set -e

# Configuration
DOMAIN="${SERVER_NAME:-localhost}"
EMAIL="${CERTBOT_EMAIL:-admin@example.com}"
STAGING="${CERTBOT_STAGING:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Function to check if certificate exists and is valid
check_certificate() {
    local cert_path="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    
    if [[ ! -f "$cert_path" ]]; then
        log "No certificate found for $DOMAIN"
        return 1
    fi
    
    # Check if certificate expires within 30 days
    if openssl x509 -checkend 2592000 -noout -in "$cert_path" > /dev/null 2>&1; then
        log "Certificate for $DOMAIN is valid and not expiring soon"
        return 0
    else
        warning "Certificate for $DOMAIN is expiring soon or invalid"
        return 1
    fi
}

# Function to generate initial certificate
generate_certificate() {
    log "Generating initial certificate for $DOMAIN"
    
    # Determine if we should use staging
    local staging_flag=""
    if [[ "$STAGING" == "1" ]]; then
        staging_flag="--staging"
        warning "Using Let's Encrypt staging environment"
    fi
    
    # Generate certificate
    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        $staging_flag \
        -d "$DOMAIN"
    
    if [[ $? -eq 0 ]]; then
        log "Certificate generated successfully for $DOMAIN"
        return 0
    else
        error "Failed to generate certificate for $DOMAIN"
        return 1
    fi
}

# Function to renew certificate
renew_certificate() {
    log "Renewing certificate for $DOMAIN"
    
    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot renew \
        --webroot \
        --webroot-path=/var/www/certbot
    
    if [[ $? -eq 0 ]]; then
        log "Certificate renewed successfully"
        # Reload nginx to pick up new certificate
        docker compose exec web nginx -s reload
        return 0
    else
        error "Failed to renew certificate"
        return 1
    fi
}

# Function to setup directories
setup_directories() {
    log "Setting up necessary directories"
    mkdir -p certbot/conf certbot/www ssl
    
    # Set proper permissions
    chmod 755 certbot/conf certbot/www ssl
}

# Main function
main() {
    log "Starting SSL certificate management for domain: $DOMAIN"
    
    # Validate domain
    if [[ "$DOMAIN" == "localhost" || "$DOMAIN" == "127.0.0.1" ]]; then
        error "Cannot generate Let's Encrypt certificate for localhost or 127.0.0.1"
        error "Please set SERVER_NAME environment variable to your actual domain"
        exit 1
    fi
    
    # Setup directories
    setup_directories
    
    # Check if certificate exists and is valid
    if check_certificate; then
        log "Certificate is valid, no action needed"
        exit 0
    fi
    
    # Generate or renew certificate
    if [[ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
        generate_certificate
    else
        renew_certificate
    fi
}

# Handle command line arguments
case "${1:-}" in
    "generate")
        setup_directories
        generate_certificate
        ;;
    "renew")
        renew_certificate
        ;;
    "check")
        check_certificate
        ;;
    *)
        main
        ;;
esac