#!/bin/bash

# Automatic SSL Certificate Renewal Cron Job
# This script should be run twice daily to check and renew certificates

# Change to the project directory
cd "$(dirname "$0")/.."

# Source environment variables if env file exists
if [[ -f "./client_management_system.env" ]]; then
    source ./client_management_system.env
fi

# Run the SSL management script in renewal mode
./scripts/ssl-management.sh renew

# Log the renewal attempt
echo "$(date): Certificate renewal check completed" >> /var/log/ssl-renewal.log