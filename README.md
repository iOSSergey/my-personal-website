# My Personal Website

Welcome to my personal website repository! This project contains the code and assets for my personal website, showcasing my skills, projects, and portfolio.

## Table of Contents
- [About](#about)
- [Quick Start](#quick-start)
- [SSL Setup](#ssl-setup)
- [Development](#development)

## Quick Start

1. Clone the repository
2. Configure your environment variables in `client_management_system.env`
3. Run with Docker Compose:

```bash
docker compose up -d
```

## SSL Setup

This project includes automated SSL certificate generation and renewal using Let's Encrypt and Certbot.

### For Production

1. Set your domain in `client_management_system.env`:
```bash
SERVER_NAME=yourdomain.com
CERTBOT_EMAIL=your-email@example.com
```

2. Run the SSL setup:
```bash
./scripts/ssl-setup.sh
```

This will automatically:
- Generate SSL certificates from Let's Encrypt
- Configure nginx with SSL
- Set up automatic certificate renewal

### For Development

The site works without SSL for local development. Just use `localhost` as the SERVER_NAME.

For more details, see [SSL Setup Documentation](docs/SSL_SETUP.md).

## Development

The project uses Docker Compose with:
- **nginx**: Web server with SSL support
- **certbot**: Automatic SSL certificate management
- **cms**: Django-based client management system

### Key Files

- `docker-compose.yml`: Main service configuration
- `config/nginx/nginx.conf`: nginx configuration
- `scripts/ssl-setup.sh`: SSL certificate setup
- `scripts/ssl-management.sh`: Certificate management utilities
