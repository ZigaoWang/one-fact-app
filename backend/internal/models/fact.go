package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Fact struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Content     string            `bson:"content" json:"content"`
	Category    string            `bson:"category" json:"category"`
	Source      string            `bson:"source" json:"source"`
	Tags        []string          `bson:"tags" json:"tags"`
	Verified    bool              `bson:"verified" json:"verified"`
	CreatedAt   time.Time         `bson:"created_at" json:"created_at"`
	UpdatedAt   time.Time         `bson:"updated_at" json:"updated_at"`
	RelatedURLs []string          `bson:"related_urls" json:"related_urls"`
	Metadata    FactMetadata      `bson:"metadata" json:"metadata"`
}

type FactMetadata struct {
	Language    string   `bson:"language" json:"language"`
	Difficulty  string   `bson:"difficulty" json:"difficulty"`
	References  []string `bson:"references" json:"references"`
	Keywords    []string `bson:"keywords" json:"keywords"`
	Popularity  int      `bson:"popularity" json:"popularity"`
	LastServed  time.Time `bson:"last_served" json:"last_served"`
	ServeCount  int      `bson:"serve_count" json:"serve_count"`
}

type FactQuery struct {
	Category    string    `json:"category"`
	Tags        []string  `json:"tags"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	SearchTerm  string    `json:"search_term"`
	Difficulty  string    `json:"difficulty"`
	Language    string    `json:"language"`
	Verified    *bool     `json:"verified"`
	Limit       int       `json:"limit"`
	Offset      int       `json:"offset"`
}
