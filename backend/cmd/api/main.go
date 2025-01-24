package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/ZigaoWang/one-fact-app/backend/internal/config"
	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/handlers"
	"github.com/ZigaoWang/one-fact-app/backend/internal/scheduler"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Printf("Error loading .env file: %v", err)
	}

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize MongoDB connection
	db, err := database.NewDatabase(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to MongoDB: %v", err)
	}

	// Initialize Redis cache
	cache, err := database.NewCache(cfg)
	if err != nil {
		log.Printf("Failed to connect to Redis: %v", err)
	}

	// Create services
	factService := services.NewFactService(db, cache)

	// Create handlers
	factHandler := handlers.NewFactHandler(factService)

	// Initialize fact scheduler
	scheduler := scheduler.NewScheduler(db.GetCollection("facts"))

	// Start scheduler in a goroutine
	go func() {
		if err := scheduler.Start(context.Background()); err != nil {
			log.Printf("Scheduler error: %v", err)
		}
	}()

	// Create router
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// API routes
	r.Route("/api/v1/facts", func(r chi.Router) {
		factHandler.RegisterRoutes(r)
	})

	// Trigger initial fact collection
	go func() {
		log.Println("Starting initial fact collection...")
		if err := scheduler.CollectFacts(context.Background()); err != nil {
			log.Printf("Error in initial fact collection: %v", err)
		}
		log.Println("Initial fact collection completed")
	}()

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
