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

# Set up secrets from .env file
echo "Setting up secrets from .env file..."
./setup_fly_secrets.sh

# Deploy the application
echo "Deploying the application to Fly.io..."
fly deploy

# Check deployment status
echo "Checking deployment status..."
fly status

echo ""
echo "Deployment completed! Your app should be available at https://one-fact-api.fly.dev"
echo "To view logs, run: fly logs"
echo ""
