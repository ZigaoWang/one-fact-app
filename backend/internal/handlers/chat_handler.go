package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
	"github.com/ZigaoWang/one-fact-app/backend/internal/services"
)

type ChatHandler struct {
	factService *services.FactService
	aiService   *services.AIService
}

func NewChatHandler(factService *services.FactService, aiService *services.AIService) *ChatHandler {
	return &ChatHandler{
		factService: factService,
		aiService:   aiService,
	}
}

func (h *ChatHandler) RegisterRoutes(r chi.Router) {
	r.Post("/", h.HandleChat)
}

// ChatRequest represents the incoming chat request
type ChatRequest struct {
	FactID   string            `json:"fact_id"`
	Messages []models.Message  `json:"messages"`
}

// HandleChat processes AI chat interactions
func (h *ChatHandler) HandleChat(w http.ResponseWriter, r *http.Request) {
	var chatRequest ChatRequest
	if err := json.NewDecoder(r.Body).Decode(&chatRequest); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Retrieve fact to provide context
	fact, err := h.fetchFactForContext(r.Context(), chatRequest.FactID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error fetching fact context: %v", err), http.StatusInternalServerError)
		return
	}

	// Process the chat interaction
	response, err := h.processChatWithAI(r.Context(), chatRequest.Messages, fact)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error processing chat: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// fetchFactForContext retrieves the fact to use as context for the AI
func (h *ChatHandler) fetchFactForContext(ctx context.Context, factID string) (*models.Fact, error) {
	// In the future, this would retrieve the fact by ID from the database
	// For now, simulate with the daily fact
	return h.factService.GetDailyFact(ctx, "", true)
}

// processChatWithAI handles the AI processing of chat messages
func (h *ChatHandler) processChatWithAI(ctx context.Context, messages []models.Message, fact *models.Fact) (*models.Message, error) {
	// Debug logging
	fmt.Printf("Processing chat with AI, fact: %+v\n", fact)
	fmt.Printf("Messages count: %d\n", len(messages))
	
	// If we have the AI service, use it
	if h.aiService != nil {
		fmt.Println("Using AI service")
		
		// Try to use AI service but catch any errors
		response, err := h.aiService.ProcessChat(ctx, messages, fact)
		if err != nil {
			fmt.Printf("AI service error: %v\n", err)
			// Fall back to simple response on error
			return &models.Message{
				Role:      "assistant",
				Content:   "I'm having trouble connecting to my knowledge base right now. Let me provide a simple response instead: " + 
				           "This fact is about " + fact.Category + ". Can you ask a more specific question?",
				Timestamp: time.Now(),
			}, nil
		}
		return response, nil
	}
	
	// Debug log if AI service is nil
	fmt.Println("AI service is nil, using fallback response")
	
	// Fallback to simple response if AI service is unavailable
	if len(messages) == 0 {
		return &models.Message{
			Role:      "assistant",
			Content:   "Hello! I'm your AI assistant for exploring today's fact. What would you like to know more about?",
			Timestamp: time.Now(),
		}, nil
	}
	
	// Basic fallback response
	return &models.Message{
		Role:      "assistant",
		Content:   fmt.Sprintf("I'd be happy to help you learn more about this %s fact. What specific aspect interests you?", fact.Category),
		Timestamp: time.Now(),
	}, nil
}
