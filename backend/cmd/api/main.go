package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/zigaowang/one-fact/internal/database"
	"github.com/zigaowang/one-fact/internal/handlers"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found")
	}

	// Initialize database
	db, err := database.InitDB()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Create router
	r := gin.Default()

	// Initialize handlers
	h := handlers.NewHandler(db)

	// API routes
	api := r.Group("/api")
	{
		// Facts endpoints
		facts := api.Group("/facts")
		{
			facts.GET("/daily", h.GetDailyFact)
			facts.GET("/random", h.GetRandomFact)
			facts.GET("/category/:category", h.GetFactsByCategory)
		}

		// Admin endpoints (to be protected)
		admin := api.Group("/admin")
		{
			admin.POST("/facts", h.CreateFact)
			admin.PUT("/facts/:id", h.UpdateFact)
			admin.DELETE("/facts/:id", h.DeleteFact)
		}
	}

	// Get port from env or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start server
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
