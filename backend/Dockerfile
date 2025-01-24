FROM golang:1.22-alpine

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git gcc musl-dev

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/api

# Use a smaller base image for the final container
FROM alpine:latest

WORKDIR /app

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata

# Copy the binary from builder
COPY --from=0 /app/main .

# Copy any additional necessary files
COPY --from=0 /app/.env.example .env

# Expose port 8080
EXPOSE 8080

# Command to run the executable
CMD ["./main"]
