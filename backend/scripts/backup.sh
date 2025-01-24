#!/bin/bash

# Get today's date for the backup filename
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/one-fact-backups"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Run backup
echo "Starting backup..."
flyctl postgres backup -a one-fact-db

# Keep only last 7 days of backups
find $BACKUP_DIR -type f -mtime +7 -name '*.dump' -delete

echo "Backup completed successfully!"
