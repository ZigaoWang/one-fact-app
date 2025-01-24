#!/bin/bash

# Make script exit on first error
set -e

echo "🚀 Deploying One Fact backend to fly.io..."

# Ensure fly.io CLI is installed
if ! command -v flyctl &> /dev/null; then
    echo "Installing fly.io CLI..."
    curl -L https://fly.io/install.sh | sh
fi

# Build the application
echo "🔨 Building application..."
go build -o app ./cmd/api

# Deploy to fly.io
echo "📦 Deploying to fly.io..."
flyctl deploy

# Run database migrations if needed
echo "🔄 Running database migrations..."
flyctl ssh console -C "/app/app migrate"

echo "✅ Deployment complete!"
