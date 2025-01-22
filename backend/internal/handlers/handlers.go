package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"github.com/zigaowang/one-fact/internal/models"
)

type Handler struct {
	db *gorm.DB
}

func NewHandler(db *gorm.DB) *Handler {
	return &Handler{db: db}
}

// GetDailyFact returns today's fact
func (h *Handler) GetDailyFact(c *gin.Context) {
	var fact models.Fact
	today := time.Now().Truncate(24 * time.Hour)
	
	result := h.db.Preload("RelatedArticles").
		Where("display_date = ? AND active = true", today).
		First(&fact)

	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "No fact available for today",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    fact,
	})
}

// GetRandomFact returns a random fact
func (h *Handler) GetRandomFact(c *gin.Context) {
	var fact models.Fact
	
	result := h.db.Preload("RelatedArticles").
		Where("active = true").
		Order("RANDOM()").
		First(&fact)

	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "No facts available",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    fact,
	})
}

// GetFactsByCategory returns facts by category
func (h *Handler) GetFactsByCategory(c *gin.Context) {
	category := models.Category(c.Param("category"))
	var facts []models.Fact

	result := h.db.Preload("RelatedArticles").
		Where("category = ? AND active = true", category).
		Order("display_date desc").
		Limit(10).
		Find(&facts)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch facts",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    facts,
	})
}

// CreateFact creates a new fact
func (h *Handler) CreateFact(c *gin.Context) {
	var fact models.Fact
	if err := c.ShouldBindJSON(&fact); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	result := h.db.Create(&fact)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create fact",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    fact,
	})
}

// UpdateFact updates an existing fact
func (h *Handler) UpdateFact(c *gin.Context) {
	id := c.Param("id")
	var fact models.Fact

	if err := h.db.First(&fact, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Fact not found",
		})
		return
	}

	if err := c.ShouldBindJSON(&fact); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	h.db.Save(&fact)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    fact,
	})
}

// DeleteFact soft deletes a fact
func (h *Handler) DeleteFact(c *gin.Context) {
	id := c.Param("id")
	result := h.db.Delete(&models.Fact{}, id)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to delete fact",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Fact deleted successfully",
	})
}
