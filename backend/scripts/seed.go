package main

import (
	"context"
	"log"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/config"
	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

var sampleFacts = []models.Fact{
	{
		ID:        primitive.NewObjectID(),
		Content:   "The first computer programmer was a woman named Ada Lovelace. She wrote the first algorithm intended to be processed by a machine in the 1840s.",
		Category:  "Technology",
		Source:    "Computer History Museum",
		Tags:      []string{"programming", "history", "women in tech"},
		Verified:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		RelatedURLs: []string{
			"https://www.computerhistory.org/babbage/adalovelace/",
		},
		Metadata: models.FactMetadata{
			Language:   "English",
			Difficulty: "Easy",
			Keywords:   []string{"Ada Lovelace", "programming", "computer history"},
			References: []string{"Computer History Museum Archives"},
			Popularity: 100,
		},
	},
	{
		ID:        primitive.NewObjectID(),
		Content:   "The Great Wall of China is not visible from space with the naked eye, contrary to popular belief. This myth has been debunked by many astronauts.",
		Category:  "History",
		Source:    "NASA",
		Tags:      []string{"architecture", "space", "myths"},
		Verified:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		RelatedURLs: []string{
			"https://www.nasa.gov/vision/space/workinginspace/great_wall.html",
		},
		Metadata: models.FactMetadata{
			Language:   "English",
			Difficulty: "Medium",
			Keywords:   []string{"Great Wall", "China", "space"},
			References: []string{"NASA Reports", "Astronaut Observations"},
			Popularity: 95,
		},
	},
	{
		ID:        primitive.NewObjectID(),
		Content:   "Quantum computers use quantum bits or 'qubits' that can exist in multiple states simultaneously, unlike classical bits that are either 0 or 1.",
		Category:  "Technology",
		Source:    "IBM Quantum Computing",
		Tags:      []string{"quantum", "computing", "physics"},
		Verified:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		RelatedURLs: []string{
			"https://www.ibm.com/quantum-computing/",
		},
		Metadata: models.FactMetadata{
			Language:   "English",
			Difficulty: "Hard",
			Keywords:   []string{"quantum computing", "qubits", "technology"},
			References: []string{"IBM Research Papers", "Quantum Computing Basics"},
			Popularity: 90,
		},
	},
}

func main() {
	ctx := context.Background()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize database
	db, err := database.NewDatabase(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close(ctx)

	// Get the facts collection
	collection := db.GetCollection("facts")

	// Insert sample facts
	for _, fact := range sampleFacts {
		_, err := collection.InsertOne(ctx, fact)
		if err != nil {
			log.Printf("Failed to insert fact: %v", err)
			continue
		}
		log.Printf("Inserted fact: %s", fact.Content[:50]+"...")
	}

	log.Println("Seed completed successfully!")
}
