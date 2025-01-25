.PHONY: install start stop restart logs clean prod-up prod-down backup check-deps install-deps

# Default environment
ENV ?= development

# Colors for pretty output
GREEN := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
RED := $(shell tput setaf 1)
RESET := $(shell tput sgr0)

# Check for required tools
DOCKER := $(shell command -v docker 2> /dev/null)
DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null)
BREW := $(shell command -v brew 2> /dev/null)

# Installation and setup
install: check-deps
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	@cd backend && go mod download
	@cd admin-panel && npm install
	@cp backend/.env.example backend/.env
	@echo "$(GREEN)Installation complete!$(RESET)"

# Check and install dependencies
check-deps:
ifndef BREW
	@echo "$(RED)Homebrew is not installed. Installing...$(RESET)"
	@/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
endif
ifndef DOCKER
	@echo "$(RED)Docker is not installed. Installing...$(RESET)"
	@brew install --cask docker
	@echo "$(YELLOW)Please open Docker Desktop and complete the installation.$(RESET)"
	@echo "$(YELLOW)After Docker is running, press any key to continue...$(RESET)"
	@read -n 1
endif
ifndef DOCKER_COMPOSE
	@echo "$(RED)Docker Compose is not installed. Installing...$(RESET)"
	@brew install docker-compose
endif
	@echo "$(GREEN)All dependencies are installed!$(RESET)"

# Development commands
start: check-deps
	@echo "$(GREEN)Starting development environment...$(RESET)"
	@docker-compose up -d
	@echo "$(GREEN)Services started:$(RESET)"
	@echo "Backend: http://localhost:8080"
	@echo "Admin Panel: http://localhost:3000"
	@echo "MongoDB: localhost:27017"
	@echo "Redis: localhost:6379"

stop:
	@echo "$(GREEN)Stopping all services...$(RESET)"
	@docker-compose down
	@echo "$(GREEN)All services stopped$(RESET)"

restart: stop start

logs:
	@docker-compose logs -f

clean:
	@echo "$(GREEN)Cleaning up...$(RESET)"
	@docker-compose down -v
	@docker system prune -f
	@echo "$(GREEN)Cleanup complete$(RESET)"

# Production commands
prod-up: check-deps
	@echo "$(GREEN)Starting production environment...$(RESET)"
	@ENV=production docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
	@echo "$(GREEN)Production services started$(RESET)"

prod-down: check-deps
	@echo "$(GREEN)Stopping production environment...$(RESET)"
	@ENV=production docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
	@echo "$(GREEN)Production services stopped$(RESET)"

# Backup command
backup:
	@echo "$(GREEN)Creating backup...$(RESET)"
	@./scripts/backup.sh
	@echo "$(GREEN)Backup complete$(RESET)"

# Help command
help:
	@echo "$(GREEN)Available commands:$(RESET)"
	@echo "  make install      - Install dependencies and setup environment"
	@echo "  make start        - Start development environment"
	@echo "  make stop         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - View logs from all services"
	@echo "  make clean        - Clean up containers and volumes"
	@echo "  make prod-up      - Start production environment"
	@echo "  make prod-down    - Stop production environment"
	@echo "  make backup       - Create backup of databases"
