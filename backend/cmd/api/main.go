package main

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ZigaoWang/one-fact-app/backend/internal/config"
	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/handlers"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
)

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Printf("Warning: Failed to load config: %v", err)
	}

	// Initialize database
	db, err := database.NewDatabase("", "")
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize services
	factService := services.NewFactService(db)

	// Add some sample data
	addSampleData(factService)

	// Initialize handlers
	factHandler := handlers.NewFactHandler(factService)

	// Create router
	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// API routes
	api := r.Group("/api")
	{
		// Facts endpoints
		facts := api.Group("/facts")
		{
			facts.GET("/daily", factHandler.GetDailyFact)
			facts.GET("/random", factHandler.GetRandomFact)
			facts.GET("/category/:category", factHandler.GetFactsByCategory)
			facts.GET("/category/:category/daily", factHandler.GetDailyFactByCategory)
		}

		// Admin endpoints (to be protected)
		admin := api.Group("/admin")
		{
			admin.POST("/facts", factHandler.CreateFact)
			admin.PUT("/facts/:id", factHandler.UpdateFact)
			admin.DELETE("/facts/:id", factHandler.DeleteFact)
		}
	}

	// Start server
	port := cfg.Port
	if port == "" {
		port = "8080"
	}
	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func addSampleData(factService *services.FactService) {
	sampleFacts := []models.Fact{
		{
			ID:       1,
			Content:  "The Great Wall of China is not visible from space with the naked eye, contrary to popular belief.",
			Category: "History",
			Source:   "NASA",
			DisplayDate: time.Now(),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      1,
					Title:   "Great Wall of China: Space View Myth",
					URL:     "https://www.nasa.gov/greatwall",
					Source:  "NASA",
					Snippet: "Learn about common myths about what's visible from space.",
				},
			},
		},
		{
			ID:       2,
			Content:  "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.",
			Category: "Science",
			Source:   "National Geographic",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      2,
					Title:   "The Science Behind Honey's Eternal Shelf Life",
					URL:     "https://www.nationalgeographic.com/honey-science",
					Source:  "National Geographic",
					Snippet: "Discover why honey is the only food that never spoils.",
				},
			},
		},
		{
			ID:       3,
			Content:  "The human brain can process images that the eyes see for as little as 13 milliseconds.",
			Category: "Science",
			Source:   "MIT Research",
			DisplayDate: time.Now(),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      3,
					Title:   "Brain Processing Speed: New Discoveries",
					URL:     "https://news.mit.edu/brain-speed",
					Source:  "MIT News",
					Snippet: "MIT researchers reveal the incredible speed of human visual processing.",
				},
			},
		},
		{
			ID:       4,
			Content:  "The first oranges weren't orange. The original oranges from Southeast Asia were actually green.",
			Category: "Science",
			Source:   "Botanical Studies",
			DisplayDate: time.Now(),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      4,
					Title:   "The Origin of Oranges",
					URL:     "https://www.botanical-studies.org/oranges",
					Source:  "Botanical Studies",
					Snippet: "Explore the fascinating history of citrus fruits.",
				},
			},
		},
		{
			ID:       5,
			Content:  "The first computer programmer was a woman. Ada Lovelace wrote the first algorithm intended to be processed by a machine.",
			Category: "Technology",
			Source:   "Computer History Museum",
			DisplayDate: time.Now(),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      5,
					Title:   "Ada Lovelace: The First Computer Programmer",
					URL:     "https://computerhistory.org/ada-lovelace",
					Source:  "Computer History Museum",
					Snippet: "Learn about the pioneering work of Ada Lovelace in computer programming.",
				},
			},
		},
		{
			ID:       6,
			Content:  "The first website went live on August 6, 1991. It was dedicated to information about the World Wide Web project.",
			Category: "Technology",
			Source:   "CERN",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:   true,
			RelatedArticles: []models.RelatedArticle{
				{
					ID:      6,
					Title:   "The Birth of the Web",
					URL:     "https://home.cern/science/computing/birth-web",
					Source:  "CERN",
					Snippet: "Discover how the World Wide Web began at CERN.",
				},
			},
		},
	}

	for _, fact := range sampleFacts {
		factService.CreateFact(nil, &fact)
	}
}
