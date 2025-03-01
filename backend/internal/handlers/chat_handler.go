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
	r.Post("/stream", h.HandleStreamChat)
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

	// Debug logging
	fmt.Printf("Received chat request: %+v\n", chatRequest)

	// Retrieve fact to provide context
	fact, err := h.fetchFactForContext(r.Context(), chatRequest.FactID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error fetching fact context: %v", err), http.StatusInternalServerError)
		return
	}

	// Log the fact being used for context
	fmt.Printf("Using fact for context: %+v\n", fact)

	// Process the chat interaction
	response, err := h.processChatWithAI(r.Context(), chatRequest.Messages, fact)
	if err != nil {
		fmt.Printf("Error in AI processing: %v\n", err)
		http.Error(w, fmt.Sprintf("Error processing chat: %v", err), http.StatusInternalServerError)
		return
	}

	// Log successful response
	fmt.Printf("Generated AI response: %s\n", response.Content)

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*") // Ensure CORS is enabled
	json.NewEncoder(w).Encode(response)
}

// fetchFactForContext retrieves the fact to use as context for the AI
func (h *ChatHandler) fetchFactForContext(ctx context.Context, factID string) (*models.Fact, error) {
	// Debug logging
	fmt.Printf("Fetching fact for context, factID: %s\n", factID)
	
	// If a specific fact ID is provided, try to get that fact
	if factID != "" && factID != "latest" {
		// In the future, this would retrieve the fact by ID from the database
		// For now, use the daily fact with empty category to get any fact
		fact, err := h.factService.GetFactByID(ctx, factID)
		if err == nil {
			return fact, nil
		}
		fmt.Printf("Error getting fact by ID: %v, falling back to random fact\n", err)
	}

	// Try to get a random fact if no specific fact is requested or if getting by ID failed
	fact, err := h.factService.GetRandomFact(ctx)
	if err != nil {
		fmt.Printf("Error getting random fact: %v\n", err)
		
		// Try daily fact as a fallback
		fact, err = h.factService.GetDailyFact(ctx, "", true)
		if err != nil {
			fmt.Printf("Error getting daily fact: %v\n", err)
			
			// Create a fallback fact for testing as last resort
			return &models.Fact{
				Content:     "This is a fallback fact used when no facts are available in the database. The One Fact app displays interesting and educational facts from various categories. Each fact is verified for accuracy before being presented to users.",
				Category:    "General",
				Source:      "One Fact App",
				Verified:    true,
				CreatedAt:   time.Now(),
				UpdatedAt:   time.Now(),
			}, nil
		}
	}
	
	return fact, nil
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
