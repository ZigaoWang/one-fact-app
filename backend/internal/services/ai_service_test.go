package services

import (
	"context"
	"os"
	"testing"

	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

func TestAIService_ProcessChat(t *testing.T) {
	// Skip test if OpenAI API key is not set
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test because OPENAI_API_KEY is not set")
	}

	service := NewAIService()
	ctx := context.Background()

	// Create a test fact
	fact := &models.Fact{
		ID:       "test-fact-id",
		Title:    "Test Fact",
		Content:  "The Great Wall of China is not visible from space with the naked eye.",
		Category: "History",
	}

	// Create test messages
	messages := []models.Message{
		{
			Role:    "user",
			Content: "Tell me more about the Great Wall of China",
		},
	}

	// Process the chat
	response, err := service.ProcessChat(ctx, messages, fact)
	if err != nil {
		t.Fatalf("Error processing chat: %v", err)
	}

	// Check response
	if response == nil {
		t.Fatal("Response is nil")
	}

	if response.Role != "assistant" {
		t.Errorf("Expected role 'assistant', got '%s'", response.Role)
	}

	if response.Content == "" {
		t.Error("Response content is empty")
	}

	t.Logf("AI Response: %s", response.Content)
}

func TestAIService_ProcessChatNoAPIKey(t *testing.T) {
	// Save the current API key and restore it after the test
	originalAPIKey := os.Getenv("OPENAI_API_KEY")
	defer os.Setenv("OPENAI_API_KEY", originalAPIKey)

	// Clear the API key for this test
	os.Setenv("OPENAI_API_KEY", "")

	service := NewAIService()
	ctx := context.Background()

	// Create a test fact
	fact := &models.Fact{
		ID:       "test-fact-id",
		Title:    "Test Fact",
		Content:  "The Great Wall of China is not visible from space with the naked eye.",
		Category: "History",
	}

	// Create test messages
	messages := []models.Message{
		{
			Role:    "user",
			Content: "Tell me more about the Great Wall of China",
		},
	}

	// Process the chat - should return error
	response, err := service.ProcessChat(ctx, messages, fact)
	
	// Without an API key, we expect an error
	if err == nil {
		t.Error("Expected error when API key is not set, but got nil")
	}

	// Response should still be nil
	if response != nil {
		t.Error("Expected nil response when API key is not set")
	}
}
