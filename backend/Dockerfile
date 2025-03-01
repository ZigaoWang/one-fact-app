FROM golang:1.21-alpine

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api

# Use a minimal alpine image for the final container
FROM alpine:latest

WORKDIR /app

# Copy the binary from builder
COPY --from=0 /app/main .
# We'll use environment variables from Fly.io secrets instead of copying the .env file

# Expose the application port
EXPOSE 8080

# Run the binary
CMD ["./main"]
