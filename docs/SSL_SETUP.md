# SSL Certificate Management with Let's Encrypt

This project includes automated SSL certificate generation and renewal using Certbot and Let's Encrypt.

## Quick Start

### 1. Configure Your Domain

Edit `client_management_system.env` and set your domain:

```bash
SERVER_NAME=yourdomain.com
CERTBOT_EMAIL=your-email@example.com
```

### 2. Run SSL Setup

```bash
./scripts/ssl-setup.sh
```

This will:
- Generate SSL certificates for your domain
- Configure nginx with SSL
- Set up automatic certificate renewal

## Manual Operations

### Generate Certificates Manually

```bash
./scripts/ssl-management.sh generate
```

### Renew Certificates

```bash
./scripts/ssl-management.sh renew
```

### Check Certificate Status

```bash
./scripts/ssl-management.sh check
```

## Development/Testing

For development with staging certificates:

```bash
export CERTBOT_STAGING=1
./scripts/ssl-setup.sh
```

## Automatic Renewal

The system includes automatic renewal in two ways:

1. **Docker Service**: The certbot container runs continuously and checks for renewal every 12 hours
2. **Cron Job** (optional): Add to your system crontab for additional reliability:

```bash
# Add this line to your crontab (crontab -e)
0 12 * * * /path/to/your/project/scripts/ssl-renewal-cron.sh
```

## File Structure

```
├── scripts/
│   ├── ssl-setup.sh           # Main SSL setup script
│   ├── ssl-management.sh      # Certificate management utilities
│   └── ssl-renewal-cron.sh    # Cron job script
├── config/nginx/
│   ├── nginx.conf             # Current nginx configuration
│   └── nginx-with-ssl.conf    # SSL-enabled nginx configuration
├── certbot/
│   ├── conf/                  # Let's Encrypt certificates and config
│   └── www/                   # Webroot for ACME challenge
└── docker-compose.certbot-init.yml  # Certbot initialization config
```

## Troubleshooting

### Certificate Generation Fails

1. Check that your domain points to your server
2. Ensure ports 80 and 443 are accessible from the internet
3. Check Docker logs: `docker compose logs certbot`

### SSL Not Working

1. Check certificate files exist: `ls -la certbot/conf/live/yourdomain.com/`
2. Check nginx configuration: `docker compose exec web nginx -t`
3. Check nginx logs: `docker compose logs web`

### Rate Limiting

Let's Encrypt has rate limits. For testing, use staging:

```bash
export CERTBOT_STAGING=1
```

## Security Notes

- Certificates are automatically renewed before expiration
- Modern SSL configuration is used (TLS 1.2+)
- HSTS headers are included for security
- Regular backups of `certbot/conf/` directory are recommended