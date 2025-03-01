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

# Set OpenAI configuration secrets
echo "Setting OpenAI configuration secrets..."

# Set OPENAI_BASE_URL
echo "Setting OPENAI_BASE_URL..."
fly secrets set OPENAI_BASE_URL=https://api.uniapi.io

# Set OPENAI_MODEL if not already set
echo "Setting OPENAI_MODEL..."
fly secrets set OPENAI_MODEL=gpt-4o-mini

echo "OpenAI secrets have been set successfully!"
echo "Redeploying the application to apply changes..."
fly deploy

# Check deployment status
echo "Checking deployment status..."
fly status
