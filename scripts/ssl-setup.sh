#!/bin/bash

# SSL Setup and Management Script
# This script handles the complete SSL setup process for the personal website

set -e

# Configuration
DOMAIN="${SERVER_NAME:-localhost}"
EMAIL="${CERTBOT_EMAIL:-admin@example.com}"
STAGING="${CERTBOT_STAGING:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Function to setup directories
setup_directories() {
    log "Setting up necessary directories"
    mkdir -p certbot/conf certbot/www ssl
    chmod 755 certbot/conf certbot/www ssl
}

# Function to check if domain is valid for Let's Encrypt
validate_domain() {
    if [[ "$DOMAIN" == "localhost" || "$DOMAIN" == "127.0.0.1" || "$DOMAIN" == "" ]]; then
        error "Cannot generate Let's Encrypt certificate for localhost, 127.0.0.1, or empty domain"
        error "Please set SERVER_NAME environment variable to your actual domain"
        return 1
    fi
    
    # Check if domain contains only valid characters
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*$ ]]; then
        error "Invalid domain name: $DOMAIN"
        return 1
    fi
    
    return 0
}

# Function to check if certificates exist
check_certificates() {
    local cert_path="./certbot/conf/live/${DOMAIN}/fullchain.pem"
    
    if [[ -f "$cert_path" ]]; then
        log "SSL certificates found for $DOMAIN"
        return 0
    else
        log "No SSL certificates found for $DOMAIN"
        return 1
    fi
}

# Function to start services without SSL first
start_http_only() {
    log "Starting services in HTTP-only mode for certificate generation"
    
    # Use the original nginx config temporarily
    cp config/nginx/nginx.conf config/nginx/nginx-backup.conf
    
    # Start only the web service first to handle ACME challenge
    docker compose up -d web cms
    
    # Wait for nginx to be ready
    sleep 5
}

# Function to generate initial certificates
generate_certificates() {
    log "Generating initial SSL certificates for $DOMAIN"
    
    local staging_flag=""
    if [[ "$STAGING" == "1" ]]; then
        staging_flag="-e CERTBOT_STAGING=1"
        warning "Using Let's Encrypt staging environment"
    fi
    
    # Run certbot to generate certificates
    docker compose -f docker-compose.yml -f docker-compose.certbot-init.yml run --rm \
        -e SERVER_NAME="$DOMAIN" \
        -e CERTBOT_EMAIL="$EMAIL" \
        $staging_flag \
        certbot
    
    if [[ $? -eq 0 ]]; then
        log "Certificates generated successfully for $DOMAIN"
        return 0
    else
        error "Failed to generate certificates for $DOMAIN"
        return 1
    fi
}

# Function to setup SSL configuration
setup_ssl_config() {
    log "Setting up SSL configuration"
    
    # Replace nginx config with SSL-enabled version
    cp config/nginx/nginx-with-ssl.conf config/nginx/nginx.conf
    
    # Restart nginx to apply SSL configuration
    docker compose restart web
    
    log "SSL configuration applied successfully"
}

# Function to setup automatic renewal
setup_renewal() {
    log "Setting up automatic certificate renewal"
    
    # Start the certbot service for automatic renewal
    docker compose up -d certbot
    
    info "Automatic renewal is now configured."
    info "Certificates will be checked for renewal every 12 hours."
    info ""
    info "To manually renew certificates, run:"
    info "  ./scripts/ssl-management.sh renew"
    info ""
    info "To set up system-wide cron job for renewal (optional):"
    info "  echo '0 12 * * * /path/to/your/project/scripts/ssl-renewal-cron.sh' | crontab -"
}

# Function to test SSL setup
test_ssl() {
    log "Testing SSL setup"
    
    # Wait a moment for nginx to reload
    sleep 5
    
    # Test HTTP to HTTPS redirect (if not localhost)
    if [[ "$DOMAIN" != "localhost" ]]; then
        info "You can test your SSL setup by visiting:"
        info "  http://$DOMAIN (should redirect to HTTPS)"
        info "  https://$DOMAIN (should work with valid certificate)"
    fi
}

# Main setup function
main() {
    log "Starting SSL setup for domain: $DOMAIN"
    
    # Setup directories
    setup_directories
    
    # Validate domain
    if ! validate_domain; then
        error "Domain validation failed. Cannot proceed with SSL setup."
        warning "For development/testing, you can:"
        warning "1. Use self-signed certificates, or"
        warning "2. Set up a proper domain name"
        exit 1
    fi
    
    # Check if certificates already exist
    if check_certificates; then
        log "Certificates already exist. Setting up SSL configuration..."
        setup_ssl_config
        setup_renewal
        test_ssl
        log "SSL setup completed successfully!"
        exit 0
    fi
    
    # Start services in HTTP-only mode
    start_http_only
    
    # Generate certificates
    if generate_certificates; then
        # Setup SSL configuration
        setup_ssl_config
        
        # Setup automatic renewal
        setup_renewal
        
        # Test the setup
        test_ssl
        
        log "SSL setup completed successfully!"
        log "Your website is now running with SSL certificates from Let's Encrypt"
    else
        error "SSL setup failed. Please check the logs above for details."
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "setup")
        main
        ;;
    "renew")
        ./scripts/ssl-management.sh renew
        ;;
    "test")
        test_ssl
        ;;
    "help"|"-h"|"--help")
        echo "SSL Setup Script for Personal Website"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup    - Run complete SSL setup (default)"
        echo "  renew    - Renew existing certificates"
        echo "  test     - Test current SSL configuration"
        echo "  help     - Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  SERVER_NAME     - Your domain name (required)"
        echo "  CERTBOT_EMAIL   - Email for Let's Encrypt notifications"
        echo "  CERTBOT_STAGING - Set to 1 to use staging environment"
        ;;
    *)
        main
        ;;
esac