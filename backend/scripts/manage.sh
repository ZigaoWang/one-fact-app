#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function start_services() {
    echo -e "${BLUE}Starting services...${NC}"
    brew services start mongodb-community
    brew services start redis
    echo -e "${GREEN}Services started${NC}"
}

function stop_services() {
    echo -e "${BLUE}Stopping services...${NC}"
    brew services stop mongodb-community
    brew services stop redis
    echo -e "${GREEN}Services stopped${NC}"
}

function restart_services() {
    echo -e "${BLUE}Restarting services...${NC}"
    brew services restart mongodb-community
    brew services restart redis
    echo -e "${GREEN}Services restarted${NC}"
}

function status_services() {
    echo -e "${BLUE}Services status:${NC}"
    brew services list | grep -E "mongodb-community|redis"
}

function show_help() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  start   - Start MongoDB and Redis services"
    echo "  stop    - Stop MongoDB and Redis services"
    echo "  restart - Restart MongoDB and Redis services"
    echo "  status  - Show services status"
}

case "$1" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        status_services
        ;;
    *)
        show_help
        ;;
esac
