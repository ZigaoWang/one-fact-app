package database

import (
	"fmt"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"github.com/zigaowang/one-fact/internal/models"
)

func InitDB() (*gorm.DB, error) {
	// Get database connection details from environment variables
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}
	
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "postgres"
	}
	
	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "postgres"
	}
	
	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "one_fact"
	}

	// Create connection string
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	// Connect to database
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %v", err)
	}

	// Auto migrate models
	err = db.AutoMigrate(&models.Fact{}, &models.RelatedArticle{})
	if err != nil {
		return nil, fmt.Errorf("failed to migrate database: %v", err)
	}

	return db, nil
}
