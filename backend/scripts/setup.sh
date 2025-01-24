#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up One Fact Backend...${NC}"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install MongoDB
echo -e "${BLUE}Installing MongoDB...${NC}"
if ! brew list mongodb-community &> /dev/null; then
    brew tap mongodb/brew
    brew install mongodb-community
    brew services start mongodb-community
    echo -e "${GREEN}MongoDB installed and started successfully${NC}"
else
    echo -e "${GREEN}MongoDB is already installed${NC}"
    brew services restart mongodb-community
    echo -e "${GREEN}MongoDB service restarted${NC}"
fi

# Install Redis
echo -e "${BLUE}Installing Redis...${NC}"
if ! brew list redis &> /dev/null; then
    brew install redis
    brew services start redis
    echo -e "${GREEN}Redis installed and started successfully${NC}"
else
    echo -e "${GREEN}Redis is already installed${NC}"
    brew services restart redis
    echo -e "${GREEN}Redis service restarted${NC}"
fi

# Create .env file if it doesn't exist
echo -e "${BLUE}Setting up environment variables...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}.env file created from .env.example${NC}"
else
    echo -e "${GREEN}.env file already exists${NC}"
fi

# Install Go dependencies
echo -e "${BLUE}Installing Go dependencies...${NC}"
go mod download
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Go dependencies installed successfully${NC}"
else
    echo -e "${RED}Error installing Go dependencies${NC}"
    exit 1
fi

# Create MongoDB indexes and initial setup
echo -e "${BLUE}Setting up MongoDB indexes...${NC}"
mongosh --eval '
    db = db.getSiblingDB("one_fact");
    db.facts.createIndex({ "content": "text" });
    db.facts.createIndex({ "category": 1 });
    db.facts.createIndex({ "tags": 1 });
    db.facts.createIndex({ "created_at": -1 });
    print("MongoDB indexes created successfully");
'

# Verify services are running
echo -e "${BLUE}Verifying services...${NC}"
if brew services list | grep mongodb-community | grep started &> /dev/null; then
    echo -e "${GREEN}MongoDB is running${NC}"
else
    echo -e "${RED}MongoDB is not running${NC}"
fi

if brew services list | grep redis | grep started &> /dev/null; then
    echo -e "${GREEN}Redis is running${NC}"
else
    echo -e "${RED}Redis is not running${NC}"
fi

# Create data directories if they don't exist
echo -e "${BLUE}Creating data directories...${NC}"
mkdir -p data/mongodb
mkdir -p data/redis

echo -e "${BLUE}Setup complete! You can now run the server with:${NC}"
echo -e "${GREEN}go run cmd/api/main.go${NC}"
