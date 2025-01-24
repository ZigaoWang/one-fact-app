package database

import (
	"context"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/config"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Database struct {
	client   *mongo.Client
	database *mongo.Database
}

func NewDatabase(cfg *config.Config) (*Database, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(cfg.MongoDB.URI))
	if err != nil {
		return nil, err
	}

	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	database := client.Database(cfg.MongoDB.Database)
	return &Database{
		client:   client,
		database: database,
	}, nil
}

func (db *Database) Close(ctx context.Context) error {
	return db.client.Disconnect(ctx)
}

func (db *Database) GetCollection(name string) *mongo.Collection {
	return db.database.Collection(name)
}

// CreateIndexes creates necessary indexes for the facts collection
func (db *Database) CreateIndexes(ctx context.Context) error {
	collection := db.GetCollection("facts")

	indexes := []mongo.IndexModel{
		{
			Keys: map[string]interface{}{
				"category": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"tags": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"content": "text",
			},
		},
		{
			Keys: map[string]interface{}{
				"metadata.language": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"metadata.difficulty": 1,
			},
		},
		{
			Keys: map[string]interface{}{
				"created_at": -1,
			},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	return err
}
