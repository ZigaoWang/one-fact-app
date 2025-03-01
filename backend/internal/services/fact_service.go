package services

import (
	"context"
	"errors"
	"log"
	"math/rand"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"github.com/ZigaoWang/one-fact-app/backend/internal/scheduler"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type FactService struct {
	db    *database.Database
	cache *database.Cache
}

func NewFactService(db *database.Database, cache *database.Cache) *FactService {
	return &FactService{
		db:    db,
		cache: cache,
	}
}

func (s *FactService) GetDailyFact(ctx context.Context, category string, isTest bool) (*models.Fact, error) {
    // Try to get from cache first (only if not in test mode and cache is available)
    if !isTest && s.cache != nil {
        if fact, err := s.cache.GetDailyFact(ctx); err == nil && fact != nil {
            if fact.Category == category {
                return fact, nil
            }
        }
    }

	// Get a random fact that hasn't been served recently for the specific category
	collection := s.db.GetCollection("facts")
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"verified": true,
			"category": category,
			"$or": []bson.M{
				{"metadata.last_served": bson.M{"$exists": false}},
				{"metadata.last_served": bson.M{
					"$lt": time.Now().Add(-24 * time.Hour),
				}},
			},
		}}},
	}

	// If in test mode, skip the last_served check
	if isTest {
		pipeline = mongo.Pipeline{
			{{Key: "$match", Value: bson.M{
				"verified": true,
				"category": category,
			}}},
		}
	}

	// Add random sampling
	pipeline = append(pipeline, bson.D{{Key: "$sample", Value: bson.M{"size": 1}}})

	cursor, err := collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var facts []models.Fact
	if err := cursor.All(ctx, &facts); err != nil {
		return nil, err
	}

	if len(facts) == 0 {
		return nil, errors.New("no facts available for category: " + category)
	}

	fact := &facts[0]

	// Update last served time and increment serve count (only if not in test mode)
	if !isTest {
		update := bson.M{
			"$set": bson.M{
				"metadata.last_served": time.Now(),
			},
			"$inc": bson.M{
				"metadata.serve_count": 1,
			},
		}

		if _, err := collection.UpdateByID(ctx, fact.ID, update); err != nil {
			return nil, err
		}

		// Cache the fact
		if err := s.cache.SetDailyFact(ctx, fact); err != nil {
			// Log error but don't fail the request
			_ = err
		}
	}

	return fact, nil
}

func (s *FactService) GetRandomFact(ctx context.Context) (*models.Fact, error) {
	collection := s.db.GetCollection("facts")
	
	// Get total count of facts
	count, err := collection.CountDocuments(ctx, bson.M{"verified": true})
	if err != nil {
		return nil, err
	}
	
	if count == 0 {
		return nil, errors.New("no facts available")
	}
	
	// Get a random skip value
	skip := rand.Int63n(count)
	
	// Find one random document
	var fact models.Fact
	err = collection.FindOne(ctx, bson.M{"verified": true}, options.FindOne().SetSkip(skip)).Decode(&fact)
	if err != nil {
		return nil, err
	}
	
	return &fact, nil
}

func (s *FactService) SearchFacts(ctx context.Context, query models.FactQuery) ([]models.Fact, error) {
	collection := s.db.GetCollection("facts")
	filter := bson.M{"verified": true}

	log.Printf("Received search query: %+v\n", query)

	if query.Category != "" {
		filter["category"] = bson.M{"$regex": primitive.Regex{Pattern: query.Category, Options: "i"}}
	}

	if len(query.Tags) > 0 && query.Tags[0] != "" {
		filter["tags"] = bson.M{"$in": query.Tags}
	}

	if query.SearchTerm != "" {
		filter["$or"] = []bson.M{
			{"content": bson.M{"$regex": query.SearchTerm, "$options": "i"}},
			{"category": bson.M{"$regex": query.SearchTerm, "$options": "i"}},
			{"tags": bson.M{"$regex": query.SearchTerm, "$options": "i"}},
			{"metadata.keywords": bson.M{"$regex": query.SearchTerm, "$options": "i"}},
		}
	}

	if query.Difficulty != "" {
		filter["metadata.difficulty"] = query.Difficulty
	}

	if query.Language != "" {
		filter["metadata.language"] = query.Language
	}

	findOptions := options.Find()
	if query.Limit > 0 {
		findOptions.SetLimit(int64(query.Limit))
	}
	if query.Offset > 0 {
		findOptions.SetSkip(int64(query.Offset))
	}

	log.Printf("Final filter: %+v\n", filter)
	cursor, err := collection.Find(ctx, filter, findOptions)
	if err != nil {
		log.Printf("Error finding facts: %v\n", err)
		return nil, err
	}
	defer cursor.Close(ctx)

	var facts []models.Fact
	if err := cursor.All(ctx, &facts); err != nil {
		log.Printf("Error decoding facts: %v\n", err)
		return nil, err
	}

	log.Printf("Found %d facts\n", len(facts))
	return facts, nil
}

func (s *FactService) AddFact(ctx context.Context, fact *models.Fact) error {
	collection := s.db.GetCollection("facts")
	_, err := collection.InsertOne(ctx, fact)
	return err
}

func (s *FactService) UpdateFact(ctx context.Context, fact *models.Fact) error {
	collection := s.db.GetCollection("facts")
	_, err := collection.ReplaceOne(ctx, bson.M{"_id": fact.ID}, fact)
	return err
}

func (s *FactService) DeleteFact(ctx context.Context, id primitive.ObjectID) error {
	collection := s.db.GetCollection("facts")
	_, err := collection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// GetFactByID retrieves a fact by its string ID
func (s *FactService) GetFactByID(ctx context.Context, id string) (*models.Fact, error) {
	// Try to convert the string ID to ObjectID
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}
	
	collection := s.db.GetCollection("facts")
	var fact models.Fact
	err = collection.FindOne(ctx, bson.M{"_id": objID}).Decode(&fact)
	if err != nil {
		return nil, err
	}
	
	return &fact, nil
}

func (s *FactService) CollectFacts(ctx context.Context) error {
    collection := s.db.GetCollection("facts")
    scheduler := scheduler.NewScheduler(collection)
    return scheduler.CollectFacts(ctx)
}