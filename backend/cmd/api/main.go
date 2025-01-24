package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/handlers"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: Error loading .env file: %v", err)
	}

	// Initialize database
	db, err := database.NewDatabase()
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize services
	factService := services.NewFactService(db)
	factFetcher := services.NewFactFetcher(factService)

	// Insert initial facts
	if err := factService.InsertInitialFacts(context.Background()); err != nil {
		log.Printf("Warning: Failed to insert initial facts: %v", err)
	}

	// Start fact fetcher in background
	go func() {
		// Fetch facts immediately on startup
		if err := factFetcher.FetchAndStoreFacts(context.Background()); err != nil {
			log.Printf("Initial fact fetch error: %v", err)
		}

		// Then fetch every 24 hours
		ticker := time.NewTicker(24 * time.Hour)
		for {
			select {
			case <-ticker.C:
				if err := factFetcher.FetchAndStoreFacts(context.Background()); err != nil {
					log.Printf("Error fetching facts: %v", err)
				}
			}
		}
	}()

	// Initialize handlers
	factHandler := handlers.NewFactHandler(factService)

	// Initialize router
	router := gin.Default()

	// Configure CORS
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"*"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	router.Use(cors.New(config))

	// Define routes
	router.GET("/api/facts/daily", factHandler.GetDailyFact)
	router.GET("/api/facts/random", factHandler.GetRandomFact)
	router.GET("/api/facts/category/:category", factHandler.GetFactsByCategory)
	router.GET("/api/facts/category/:category/daily", factHandler.GetDailyFactByCategory)
	router.POST("/api/facts", factHandler.CreateFact)
	router.PUT("/api/facts/:id", factHandler.UpdateFact)
	router.DELETE("/api/facts/:id", factHandler.DeleteFact)

	// Get port from environment variable or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Create server with graceful shutdown
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s\n", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v\n", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// Give outstanding requests 5 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("Server exiting")
}
