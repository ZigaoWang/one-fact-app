# One Fact Backend

A modern, scalable backend for the One Fact app using Go, MongoDB, and Redis.

## Features

- Clean, modular architecture
- MongoDB for persistent storage
- Redis for caching and performance
- RESTful API endpoints
- Full-text search support
- Fact categorization and tagging
- Automatic daily fact rotation
- Performance metrics and tracking

## Prerequisites

- Go 1.16 or later
- MongoDB 4.4 or later
- Redis 6.0 or later

## Project Structure

```
backend/
├── cmd/
│   └── api/            # Application entrypoints
├── internal/
│   ├── config/         # Configuration management
│   ├── models/         # Data models
│   ├── handlers/       # HTTP handlers
│   ├── services/       # Business logic
│   └── database/       # Database and cache interfaces
└── scripts/           # Utility scripts
```

## API Endpoints

- `GET /api/v1/facts/daily` - Get the daily fact
- `GET /api/v1/facts/search` - Search facts with filters
- `POST /api/v1/facts` - Add a new fact
- `PUT /api/v1/facts/{id}` - Update a fact
- `DELETE /api/v1/facts/{id}` - Delete a fact

## Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and configure your environment variables
3. Install dependencies:
   ```bash
   go mod download
   ```
4. Run the server:
   ```bash
   go run cmd/api/main.go
   ```

## Configuration

Configure the following environment variables in `.env`:

- `PORT` - Server port (default: 8080)
- `MONGODB_URI` - MongoDB connection string
- `REDIS_HOST` - Redis host
- `REDIS_PORT` - Redis port
- `API_SECRET` - API secret key
- `CORS_ALLOWED_ORIGINS` - Allowed CORS origins

## Development

To run in development mode:

```bash
go run cmd/api/main.go
```

## Production

Build the binary:

```bash
go build -o server cmd/api/main.go
```

Run in production:

```bash
./server
```
