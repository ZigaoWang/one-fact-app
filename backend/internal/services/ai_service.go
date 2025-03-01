package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

// AIService handles interactions with AI providers
type AIService struct {
	httpClient *http.Client
	apiKey     string
	baseURL    string
}

// NewAIService creates a new AI service instance
func NewAIService() *AIService {
	apiKey := os.Getenv("OPENAI_API_KEY")
	baseURL := os.Getenv("OPENAI_BASE_URL")
	
	// Log configuration status
	if apiKey == "" {
		fmt.Println("Warning: OPENAI_API_KEY is not set. AI features will be limited.")
	}
	
	if baseURL == "" {
		baseURL = "https://api.openai.com" // Default if not specified
		fmt.Println("Info: Using default OpenAI base URL")
	}
	
	return &AIService{
		httpClient: &http.Client{
			Timeout: time.Second * 30, // Longer timeout for AI requests
		},
		apiKey:  apiKey,
		baseURL: baseURL,
	}
}

// Message represents a chat message for the OpenAI API
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// CompletionRequest is the request structure for chat completions
type CompletionRequest struct {
	Model       string    `json:"model"`
	Messages    []Message `json:"messages"`
	Temperature float64   `json:"temperature"`
	MaxTokens   int       `json:"max_tokens,omitempty"`
}

// CompletionResponse is the response structure from OpenAI
type CompletionResponse struct {
	ID      string `json:"id"`
	Object  string `json:"object"`
	Created int64  `json:"created"`
	Choices []struct {
		Index   int `json:"index"`
		Message struct {
			Role    string `json:"role"`
			Content string `json:"content"`
		} `json:"message"`
		FinishReason string `json:"finish_reason"`
	} `json:"choices"`
	Usage struct {
		PromptTokens     int `json:"prompt_tokens"`
		CompletionTokens int `json:"completion_tokens"`
		TotalTokens      int `json:"total_tokens"`
	} `json:"usage"`
}

// ProcessChat sends messages to OpenAI and returns the AI response
func (s *AIService) ProcessChat(ctx context.Context, messages []models.Message, fact *models.Fact) (*models.Message, error) {
	if s.apiKey == "" {
		return nil, fmt.Errorf("OpenAI API key is not set")
	}

	// Set the base URL with a default if not specified
	baseURL := s.baseURL
	if baseURL == "" {
		baseURL = "https://api.openai.com"
	}

	// Create system message with fact context
	systemMessage := Message{
		Role: "system",
		Content: fmt.Sprintf(
			"You are an educational AI assistant in the 'One Fact' app. Today's fact is about: %s\n\nCategory: %s\nSource: %s\n\nYour goal is to help the user explore this fact in depth. Provide accurate information and engage the user in learning more about related concepts.",
			fact.Content,
			fact.Category,
			fact.Source,
		),
	}

	// Convert app messages to OpenAI format
	apiMessages := []Message{systemMessage}
	for _, msg := range messages {
		// Skip system messages as we've already added our custom one
		if msg.Role == "system" {
			continue
		}
		apiMessages = append(apiMessages, Message{
			Role:    msg.Role,
			Content: msg.Content,
		})
	}

	// Get model from environment or use default
	model := os.Getenv("OPENAI_MODEL")
	if model == "" {
		model = "gpt-3.5-turbo" // Default model
	}
	
	// Prepare request
	reqBody := CompletionRequest{
		Model:       model,
		Messages:    apiMessages,
		Temperature: 0.7,
		MaxTokens:   800, // Adjust as needed
	}

	reqBytes, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("error marshaling request: %w", err)
	}

	// Create request
	req, err := http.NewRequestWithContext(
		ctx,
		"POST",
		fmt.Sprintf("%s/v1/chat/completions", baseURL),
		bytes.NewBuffer(reqBytes),
	)
	if err != nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}

	// Add headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", s.apiKey))

	// Send request
	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error sending request: %w", err)
	}
	defer resp.Body.Close()

	// Check status code
	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API returned non-200 status code %d: %s", resp.StatusCode, string(bodyBytes))
	}

	// Parse response
	var completionResp CompletionResponse
	if err := json.NewDecoder(resp.Body).Decode(&completionResp); err != nil {
		return nil, fmt.Errorf("error decoding response: %w", err)
	}

	// Extract the assistant's message
	if len(completionResp.Choices) == 0 {
		return nil, fmt.Errorf("no choices returned from the API")
	}

	// Create and return the response message
	return &models.Message{
		Role:      "assistant",
		Content:   completionResp.Choices[0].Message.Content,
		Timestamp: time.Now(),
	}, nil
}
