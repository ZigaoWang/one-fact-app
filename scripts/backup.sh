#!/bin/bash

# Create backup directory if it doesn't exist
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

# Get current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup MongoDB
echo "Backing up MongoDB..."
docker-compose exec -T mongodb mongodump --archive > "$BACKUP_DIR/mongodb_$TIMESTAMP.archive"

# Backup Redis
echo "Backing up Redis..."
docker-compose exec -T redis redis-cli SAVE
docker-compose cp redis:/data/dump.rdb "$BACKUP_DIR/redis_$TIMESTAMP.rdb"

# Create environment backup
echo "Backing up environment files..."
cp .env "$BACKUP_DIR/env_$TIMESTAMP.backup"

# Compress all backups
echo "Compressing backups..."
tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" \
    "$BACKUP_DIR/mongodb_$TIMESTAMP.archive" \
    "$BACKUP_DIR/redis_$TIMESTAMP.rdb" \
    "$BACKUP_DIR/env_$TIMESTAMP.backup"

# Clean up individual files
rm "$BACKUP_DIR/mongodb_$TIMESTAMP.archive" \
   "$BACKUP_DIR/redis_$TIMESTAMP.rdb" \
   "$BACKUP_DIR/env_$TIMESTAMP.backup"

echo "Backup completed: $BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# Keep only last 5 backups
cd "$BACKUP_DIR" && ls -t *.tar.gz | tail -n +6 | xargs -r rm --

echo "Cleaned up old backups"
