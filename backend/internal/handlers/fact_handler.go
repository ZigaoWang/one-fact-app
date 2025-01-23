package handlers

import (
	"net/http"
	"strconv"

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

func (h *FactHandler) GetDailyFact(c *gin.Context) {
	fact, err := h.factService.GetDailyFact(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Use gin's JSON method with proper indentation
	c.IndentedJSON(http.StatusOK, fact)
}

func (h *FactHandler) GetRandomFact(c *gin.Context) {
	fact, err := h.factService.GetRandomFact(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.IndentedJSON(http.StatusOK, fact)
}

func (h *FactHandler) GetFactsByCategory(c *gin.Context) {
	category := c.Param("category")
	facts, err := h.factService.GetFactsByCategory(c.Request.Context(), category)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.IndentedJSON(http.StatusOK, facts)
}

func (h *FactHandler) GetDailyFactByCategory(c *gin.Context) {
	category := c.Param("category")
	fact, err := h.factService.GetDailyFactByCategory(c.Request.Context(), category)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.IndentedJSON(http.StatusOK, fact)
}

func (h *FactHandler) CreateFact(c *gin.Context) {
	var fact models.Fact
	if err := c.ShouldBindJSON(&fact); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.factService.CreateFact(c.Request.Context(), &fact); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.IndentedJSON(http.StatusCreated, fact)
}

func (h *FactHandler) UpdateFact(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid fact ID"})
		return
	}

	var fact models.Fact
	if err := c.ShouldBindJSON(&fact); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fact.ID = id
	if err := h.factService.UpdateFact(c.Request.Context(), idStr, &fact); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.IndentedJSON(http.StatusOK, fact)
}

func (h *FactHandler) DeleteFact(c *gin.Context) {
	idStr := c.Param("id")
	if err := h.factService.DeleteFact(c.Request.Context(), idStr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}
