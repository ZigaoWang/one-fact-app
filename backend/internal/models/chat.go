package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Message represents a chat message in a conversation
type Message struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id,omitempty"`
	Role      string            `bson:"role" json:"role"`
	Content   string            `bson:"content" json:"content"`
	FactID    string            `bson:"fact_id" json:"fact_id,omitempty"`
	UserID    string            `bson:"user_id,omitempty" json:"user_id,omitempty"`
	Timestamp time.Time         `bson:"timestamp" json:"timestamp"`
}

// ChatSession represents a conversation between a user and the AI
type ChatSession struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID      string            `bson:"user_id,omitempty" json:"user_id,omitempty"`
	FactID      string            `bson:"fact_id" json:"fact_id"`
	Messages    []Message         `bson:"messages" json:"messages"`
	CreatedAt   time.Time         `bson:"created_at" json:"created_at"`
	UpdatedAt   time.Time         `bson:"updated_at" json:"updated_at"`
	Title       string            `bson:"title,omitempty" json:"title,omitempty"`
	IsArchived  bool              `bson:"is_archived" json:"is_archived"`
}
