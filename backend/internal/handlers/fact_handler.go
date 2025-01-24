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
	r.Get("/daily", h.GetDailyFact)
	r.Get("/search", h.SearchFacts)
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(fact)
}

func (h *FactHandler) SearchFacts(w http.ResponseWriter, r *http.Request) {
	var query models.FactQuery
	query.Category = r.URL.Query().Get("category")
	query.SearchTerm = r.URL.Query().Get("q")
	query.Difficulty = r.URL.Query().Get("difficulty")
	query.Language = r.URL.Query().Get("language")

	// Parse other query parameters as needed

	facts, err := h.factService.SearchFacts(r.Context(), query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(facts)
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

	w.WriteHeader(http.StatusCreated)
}

func (h *FactHandler) UpdateFact(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	var fact models.Fact
	if err := json.NewDecoder(r.Body).Decode(&fact); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fact.ID = objectID
	if err := h.factService.UpdateFact(r.Context(), &fact); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (h *FactHandler) DeleteFact(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if err := h.factService.DeleteFact(r.Context(), objectID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func respondJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
