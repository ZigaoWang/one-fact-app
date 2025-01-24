package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/ZigaoWang/one-fact-app/backend/internal/processors"
)

// FactHandler handles fact-related HTTP endpoints
type FactHandler struct {
	collection *mongo.Collection
}

// NewFactHandler creates a new fact handler
func NewFactHandler(collection *mongo.Collection) *FactHandler {
	return &FactHandler{
		collection: collection,
	}
}

// Routes returns the router with all fact-related routes
func (h *FactHandler) Routes() chi.Router {
	r := chi.NewRouter()

	r.Get("/daily", h.GetDailyFact)
	r.Get("/random", h.GetRandomFact)
	r.Get("/search", h.SearchFacts)
	r.Get("/categories", h.GetCategories)
	r.Get("/category/{category}", h.GetFactsByCategory)

	return r
}

// GetDailyFact returns the fact of the day
func (h *FactHandler) GetDailyFact(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	today := time.Now().UTC().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	filter := bson.M{
		"publish_date": bson.M{
			"$gte": today,
			"$lt":  tomorrow,
		},
	}

	var fact processors.ProcessedFact
	err := h.collection.FindOne(ctx, filter).Decode(&fact)
	if err != nil {
		// If no fact is scheduled for today, get a random one
		if err == mongo.ErrNoDocuments {
			h.GetRandomFact(w, r)
			return
		}
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to fetch daily fact"})
		return
	}

	render.JSON(w, r, fact)
}

// GetRandomFact returns a random fact
func (h *FactHandler) GetRandomFact(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	pipeline := []bson.M{
		{"$sample": bson.M{"size": 1}},
	}

	cursor, err := h.collection.Aggregate(ctx, pipeline)
	if err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to fetch random fact"})
		return
	}
	defer cursor.Close(ctx)

	var facts []processors.ProcessedFact
	if err := cursor.All(ctx, &facts); err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to decode fact"})
		return
	}

	if len(facts) == 0 {
		render.Status(r, http.StatusNotFound)
		render.JSON(w, r, map[string]string{"error": "No facts available"})
		return
	}

	render.JSON(w, r, facts[0])
}

// SearchFacts searches facts based on query parameters
func (h *FactHandler) SearchFacts(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	query := r.URL.Query().Get("q")
	category := r.URL.Query().Get("category")
	tag := r.URL.Query().Get("tag")

	filter := bson.M{}
	if query != "" {
		filter["$text"] = bson.M{"$search": query}
	}
	if category != "" {
		filter["category"] = category
	}
	if tag != "" {
		filter["tags"] = tag
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "score", Value: -1}}).
		SetLimit(20)

	cursor, err := h.collection.Find(ctx, filter, opts)
	if err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to search facts"})
		return
	}
	defer cursor.Close(ctx)

	var facts []processors.ProcessedFact
	if err := cursor.All(ctx, &facts); err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to decode facts"})
		return
	}

	render.JSON(w, r, facts)
}

// GetCategories returns all available fact categories
func (h *FactHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	pipeline := []bson.M{
		{"$group": bson.M{"_id": "$category"}},
		{"$sort": bson.M{"_id": 1}},
	}

	cursor, err := h.collection.Aggregate(ctx, pipeline)
	if err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to fetch categories"})
		return
	}
	defer cursor.Close(ctx)

	var categories []string
	for cursor.Next(ctx) {
		var result struct {
			ID string `bson:"_id"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		categories = append(categories, result.ID)
	}

	render.JSON(w, r, categories)
}

// GetFactsByCategory returns facts for a specific category
func (h *FactHandler) GetFactsByCategory(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	category := chi.URLParam(r, "category")

	opts := options.Find().
		SetSort(bson.D{{Key: "publish_date", Value: -1}}).
		SetLimit(20)

	cursor, err := h.collection.Find(ctx, bson.M{"category": category}, opts)
	if err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to fetch facts"})
		return
	}
	defer cursor.Close(ctx)

	var facts []processors.ProcessedFact
	if err := cursor.All(ctx, &facts); err != nil {
		render.Status(r, http.StatusInternalServerError)
		render.JSON(w, r, map[string]string{"error": "Failed to decode facts"})
		return
	}

	render.JSON(w, r, facts)
}
