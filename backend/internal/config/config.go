package config

import (
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Server   ServerConfig
	MongoDB  MongoDBConfig
	Redis    RedisConfig
	API      APIConfig
	Services ServiceConfig
}

type ServerConfig struct {
	Port string
	Env  string
}

type MongoDBConfig struct {
	URI      string
	Database string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

type APIConfig struct {
	Secret           string
	AllowedOrigins   string
}

type ServiceConfig struct {
	FactFetchInterval time.Duration
	CacheTTL         time.Duration
}

func Load() (*Config, error) {
	if err := godotenv.Load(); err != nil {
		// Allow missing .env file in production
		if os.Getenv("ENV") != "production" {
			return nil, err
		}
	}

	factFetchInterval, err := time.ParseDuration(getEnv("FACT_FETCH_INTERVAL", "24h"))
	if err != nil {
		return nil, err
	}

	cacheTTL, err := time.ParseDuration(getEnv("CACHE_TTL", "24h"))
	if err != nil {
		return nil, err
	}

	return &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
			Env:  getEnv("ENV", "development"),
		},
		MongoDB: MongoDBConfig{
			URI:      getEnv("MONGODB_URI", "mongodb://localhost:27017"),
			Database: getEnv("MONGODB_DATABASE", "one_fact"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       0,
		},
		API: APIConfig{
			Secret:         getEnv("API_SECRET", "your_secret_key_here"),
			AllowedOrigins: getEnv("CORS_ALLOWED_ORIGINS", "*"),
		},
		Services: ServiceConfig{
			FactFetchInterval: factFetchInterval,
			CacheTTL:         cacheTTL,
		},
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
