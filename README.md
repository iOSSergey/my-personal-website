# My Personal Website

Welcome to my personal website repository! This project contains the code and assets for my personal website, showcasing my skills, projects, and portfolio.

## Table of Contents

- [About](#about)
- [SSL Certificate Management](#ssl-certificate-management)
- [Getting Started](#getting-started)

## SSL Certificate Management

This project uses Let's Encrypt for automatic SSL certificate management for **iossergey.online**.

### Initial Setup

1. Set your `SERVER_NAME=iossergey.online` in `client_management_system.env`
2. Run initial certificate creation: `./scripts/init-letsencrypt.sh`
3. Certificates will be created for both `iossergey.online` and `www.iossergey.online`

### Automatic Renewal

The certbot container automatically renews certificates every 12 hours and reloads nginx configuration.

### Manual Renewal

To manually renew certificates: `./scripts/renew-certificates.sh`

## Getting Started

1. Clone the repository
2. Set up environment variables in `client_management_system.env`
3. Run `docker-compose up -d`
