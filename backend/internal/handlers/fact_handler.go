package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type FactHandler struct {
	factService *services.FactService
}

func NewFactHandler(factService *services.FactService) *FactHandler {
	return &FactHandler{
		factService: factService,
	}
}

func (h *FactHandler) RegisterRoutes(r chi.Router) {
	r.Get("/", h.GetAllFacts)
	r.Get("/daily", h.GetDailyFact)
	r.Get("/random", h.GetRandomFact)
	r.Get("/search", h.SearchFacts)
	r.Get("/categories", h.GetCategories)
	r.Get("/category/{category}", h.GetFactsByCategory)
	r.Post("/", h.AddFact)
	r.Put("/{id}", h.UpdateFact)
	r.Delete("/{id}", h.DeleteFact)
}

func (h *FactHandler) GetDailyFact(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	if category == "" {
		category = "Technology" // Default category
	}

	// Secret test mode parameter
	isTest := r.URL.Query().Get("test_mode") == "true"

	fact, err := h.factService.GetDailyFact(r.Context(), category, isTest)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, fact)
}

func (h *FactHandler) GetRandomFact(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	fact, err := h.factService.GetDailyFact(r.Context(), category, true) // Use test mode to get random fact
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, fact)
}

func (h *FactHandler) SearchFacts(w http.ResponseWriter, r *http.Request) {
	query := models.FactQuery{
		SearchTerm: r.URL.Query().Get("q"),
		Category:   r.URL.Query().Get("category"),
		Tags:       []string{r.URL.Query().Get("tag")},
	}

	facts, err := h.factService.SearchFacts(r.Context(), query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, facts)
}

func (h *FactHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	categories := []string{
		"Science",
		"Technology",
		"History",
		"Geography",
		"Arts",
		"Culture",
		"Sports",
		"Entertainment",
		"Politics",
		"Business",
		"Education",
		"Health",
		"Environment",
		"Space",
		"Nature",
		"Mathematics",
	}
	respondJSON(w, categories)
}

func (h *FactHandler) GetFactsByCategory(w http.ResponseWriter, r *http.Request) {
	category := chi.URLParam(r, "category")
	query := models.FactQuery{
		Category: category,
	}

	facts, err := h.factService.SearchFacts(r.Context(), query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, facts)
}

func (h *FactHandler) AddFact(w http.ResponseWriter, r *http.Request) {
	var fact models.Fact
	if err := json.NewDecoder(r.Body).Decode(&fact); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := h.factService.AddFact(r.Context(), &fact); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, fact)
}

func (h *FactHandler) UpdateFact(w http.ResponseWriter, r *http.Request) {
	var fact models.Fact
	if err := json.NewDecoder(r.Body).Decode(&fact); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	idStr := chi.URLParam(r, "id")
	id, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}
	fact.ID = id

	if err := h.factService.UpdateFact(r.Context(), &fact); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, fact)
}

func (h *FactHandler) DeleteFact(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := h.factService.DeleteFact(r.Context(), id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *FactHandler) GetAllFacts(w http.ResponseWriter, r *http.Request) {
	query := models.FactQuery{} // Empty query to get all facts
	facts, err := h.factService.SearchFacts(r.Context(), query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	respondJSON(w, facts)
}

func respondJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
