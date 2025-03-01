#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if fly CLI is installed
if ! command -v fly &> /dev/null; then
    echo "Error: fly CLI is not installed. Please install it first:"
    echo "brew install flyctl"
    exit 1
fi

# Check if logged in to Fly.io
echo "Checking Fly.io authentication status..."
if ! fly auth whoami &> /dev/null; then
    echo "You need to log in to Fly.io first."
    fly auth login
fi

# Enable debug logging for the app
echo "Enabling debug logging for the app..."
fly secrets set DEBUG=true

# Print all current secrets
echo "Current secrets:"
fly secrets list

# Redeploy the app with debug mode
echo "Redeploying the app with debug mode..."
fly deploy

# Watch logs
echo "Watching logs for errors..."
fly logs
