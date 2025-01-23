package handlers

import (
	"net/http"
	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
)

type FactHandler struct {
	factService *services.FactService
}

func NewFactHandler(factService *services.FactService) *FactHandler {
	return &FactHandler{
		factService: factService,
	}
}

// Custom JSON response function that formats dates in ISO 8601
func respondWithJSON(c *gin.Context, code int, obj interface{}) {
	c.Writer.Header().Set("Content-Type", "application/json")
	c.Writer.WriteHeader(code)

	encoder := json.NewEncoder(c.Writer)
	encoder.SetIndent("", "  ")
	encoder.Encode(obj)
}

// GetDailyFact handles GET /api/facts/daily
func (h *FactHandler) GetDailyFact(c *gin.Context) {
	fact, err := h.factService.GetDailyFact(c.Request.Context())
	if err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	respondWithJSON(c, http.StatusOK, gin.H{
		"success": true,
		"data": fact,
	})
}

// GetRandomFact handles GET /api/facts/random
func (h *FactHandler) GetRandomFact(c *gin.Context) {
	fact, err := h.factService.GetRandomFact(c.Request.Context())
	if err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	respondWithJSON(c, http.StatusOK, gin.H{
		"success": true,
		"data": fact,
	})
}

// CreateFact handles POST /api/admin/facts
func (h *FactHandler) CreateFact(c *gin.Context) {
	var fact models.Fact
	if err := c.ShouldBindJSON(&fact); err != nil {
		respondWithJSON(c, http.StatusBadRequest, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	if err := h.factService.CreateFact(c.Request.Context(), &fact); err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	respondWithJSON(c, http.StatusCreated, gin.H{
		"success": true,
		"data": fact,
	})
}

// UpdateFact handles PUT /api/admin/facts/:id
func (h *FactHandler) UpdateFact(c *gin.Context) {
	id := c.Param("id")
	var fact models.Fact
	if err := c.ShouldBindJSON(&fact); err != nil {
		respondWithJSON(c, http.StatusBadRequest, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	if err := h.factService.UpdateFact(c.Request.Context(), id, &fact); err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	respondWithJSON(c, http.StatusOK, gin.H{
		"success": true,
		"data": fact,
	})
}

// DeleteFact handles DELETE /api/admin/facts/:id
func (h *FactHandler) DeleteFact(c *gin.Context) {
	id := c.Param("id")

	if err := h.factService.DeleteFact(c.Request.Context(), id); err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	respondWithJSON(c, http.StatusOK, gin.H{
		"success": true,
		"data": nil,
	})
}

// GetFactsByCategory handles GET /api/facts/category/:category
func (h *FactHandler) GetFactsByCategory(c *gin.Context) {
	category := c.Param("category")
	facts, err := h.factService.GetFactsByCategory(c.Request.Context(), category)
	if err != nil {
		respondWithJSON(c, http.StatusInternalServerError, gin.H{
			"success": false,
			"error": err.Error(),
		})
		return
	}

	// Return all facts in the category
	respondWithJSON(c, http.StatusOK, gin.H{
		"success": true,
		"data": facts,
	})
}
