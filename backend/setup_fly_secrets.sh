#!/bin/bash

# This script sets up secrets in Fly.io based on the .env file

# Check if fly CLI is installed
if ! command -v fly &> /dev/null; then
    echo "Error: fly CLI is not installed. Please install it first."
    echo "Visit https://fly.io/docs/hands-on/install-flyctl/ for installation instructions."
    exit 1
fi

# Check if logged in to Fly.io
echo "Checking if logged in to Fly.io..."
if ! fly auth whoami &> /dev/null; then
    echo "You need to log in to Fly.io first."
    fly auth login
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please create it first."
    exit 1
fi

# Set secrets from .env file
echo "Setting secrets from .env file..."
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
        continue
    fi
    
    # Extract key and value
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)
    
    # Set the secret
    echo "Setting secret: $key"
    fly secrets set "$key=$value"
done < .env

echo "All secrets have been set successfully!"
