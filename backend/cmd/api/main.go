package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/ZigaoWang/one-fact-app/internal/database"
	"github.com/ZigaoWang/one-fact-app/internal/handlers"
)

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found")
	}

	// Initialize database connection
	db, err := database.InitDB()
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Create handler instance
	h := handlers.NewHandler(db)

	// Initialize Gin router
	r := gin.Default()

	// Add CORS middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "Content-Length")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Add response headers middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Content-Type", "application/json; charset=utf-8")
		c.Next()
	})

	// Define API routes
	api := r.Group("/api")
	{
		// Core endpoints
		api.GET("/fact/daily", h.GetDailyFact)
		api.GET("/fact/articles", h.GetRelatedArticles)
		api.POST("/chat/message", h.HandleChatMessage)
		api.GET("/chat/context", h.GetFactContext)
	}

	// Get port from env or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "5000"
	}

	// Configure Gin to properly format JSON responses
	gin.SetMode(gin.ReleaseMode)
	r.Use(gin.Recovery())

	// Start the server
	log.Printf("Starting server on port %s...\n", port)
	if err := r.Run("0.0.0.0:" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
