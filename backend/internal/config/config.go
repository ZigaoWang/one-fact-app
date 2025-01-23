package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the application
type Config struct {
	Port     string
	MongoURI string
	DBName   string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() (*Config, error) {
	if err := godotenv.Load(); err != nil {
		fmt.Println("Warning: .env file not found")
	}

	config := &Config{
		Port:     getEnvOrDefault("PORT", "8080"),
		MongoURI: getEnvOrDefault("MONGO_URI", "mongodb://localhost:27017"),
		DBName:   getEnvOrDefault("DB_NAME", "one_fact"),
	}

	return config, nil
}

// getEnvOrDefault returns the value of an environment variable or a default value
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
