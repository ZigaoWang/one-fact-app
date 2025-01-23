package database

import (
	"fmt"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"github.com/ZigaoWang/one-fact-app/internal/models"
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
	
	// Create the database connection string
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	
	// Open database connection
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %v", err)
	}

	// Auto-migrate the models
	err = db.AutoMigrate(&models.Fact{}, &models.RelatedArticle{})
	if err != nil {
		return nil, fmt.Errorf("failed to migrate database: %v", err)
	}

	// Add some sample data if the database is empty
	var count int64
	db.Model(&models.Fact{}).Count(&count)
	if count == 0 {
		// Create a sample fact
		sampleURL := "https://en.wikipedia.org/wiki/Honey"
		fact := models.Fact{
			Content:     "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.",
			Category:    "Science",
			Source:      "National Geographic",
			URL:         &sampleURL,
			DisplayDate: models.Fact{}.CreatedAt,
			Active:      true,
			RelatedArticles: []models.RelatedArticle{
				{
					Title:    "The Science Behind Honey's Eternal Shelf Life",
					URL:      "https://www.smithsonianmag.com/science-nature/the-science-behind-honeys-eternal-shelf-life-1218690/",
					Source:   "Smithsonian Magazine",
					Snippet:  "Modern archeologists, excavating ancient Egyptian tombs, have often found something unexpected amongst the tombs' artifacts: pots of honey, thousands of years old, and yet still preserved.",
				},
			},
		}
		db.Create(&fact)
	}
	
	return db, nil
}
