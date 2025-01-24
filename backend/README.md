# One Fact Backend

A modern, automated fact collection and distribution API built with Go, MongoDB, and Redis.

## Features

- Automated fact collection from multiple sources
- Intelligent fact processing and validation
- Content scheduling and rotation
- RESTful API endpoints
- MongoDB for persistent storage
- Redis for caching and performance
- Full-text search support
- Fact categorization and tagging

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
│   ├── collectors/     # Fact collection sources
│   ├── processors/     # Fact validation and enrichment
│   ├── scheduler/      # Automated collection scheduling
│   ├── config/         # Configuration management
│   ├── models/         # Data models
│   ├── handlers/       # HTTP handlers
│   ├── services/       # Business logic
│   └── database/       # Database and cache interfaces
└── scripts/           # Utility scripts
```

## API Endpoints

### Facts

- `GET /api/v1/facts/daily` - Get today's fact
  - Response: Single fact object
  - No parameters required

- `GET /api/v1/facts/random` - Get a random fact
  - Response: Single fact object
  - No parameters required

- `GET /api/v1/facts/search` - Search facts with filters
  - Parameters:
    - `q` (string, optional): Search query
    - `category` (string, optional): Filter by category
    - `tag` (string, optional): Filter by tag
  - Response: Array of facts

- `GET /api/v1/facts/categories` - Get all available categories
  - Response: Array of category strings

- `GET /api/v1/facts/category/{category}` - Get facts by category
  - Parameters:
    - `category` (string): Category name in URL
  - Response: Array of facts

### Fact Object Structure

```json
{
  "id": "string",
  "content": "string",
  "source": "string",
  "category": "string",
  "tags": ["string"],
  "urls": ["string"],
  "metadata": {
    "key": "value"
  },
  "verified": boolean,
  "score": number,
  "created_at": "datetime",
  "updated_at": "datetime",
  "publish_date": "datetime"
}
```

## Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and configure your environment variables
3. Install dependencies:
   ```bash
   go mod download
   ```
4. Run the setup script:
   ```bash
   ./scripts/setup.sh
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

## Docker Deployment

Build the Docker image:

```bash
docker build -t one-fact-backend .
```

Run with Docker:

```bash
docker run -p 8080:8080 one-fact-backend
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
