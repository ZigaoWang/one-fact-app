package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// HandleStreamChat processes AI chat interactions with streaming responses
func (h *ChatHandler) HandleStreamChat(w http.ResponseWriter, r *http.Request) {
	var chatRequest ChatRequest
	if err := json.NewDecoder(r.Body).Decode(&chatRequest); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Debug logging
	fmt.Printf("Received streaming chat request: %+v\n", chatRequest)

	// Retrieve fact to provide context
	fact, err := h.fetchFactForContext(r.Context(), chatRequest.FactID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error fetching fact context: %v", err), http.StatusInternalServerError)
		return
	}

	// Log the fact being used for context
	fmt.Printf("Using fact for streaming context: %+v\n", fact)

	// Set headers for SSE
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Process the chat interaction with streaming
	if h.aiService == nil {
		// If AI service is not available, send a fallback response
		fmt.Printf("AI service is nil, using fallback for streaming\n")
		
		// Send a simple message
		fmt.Fprintf(w, "data: I'm sorry, but the AI service is currently unavailable. \n\n")
		w.(http.Flusher).Flush()
		
		time.Sleep(500 * time.Millisecond)
		
		fmt.Fprintf(w, "data: Please try again later or contact support if this issue persists.\n\n")
		w.(http.Flusher).Flush()
		
		// Send completion signal
		fmt.Fprintf(w, "data: [DONE]\n\n")
		w.(http.Flusher).Flush()
		return
	}

	// Use the AI service for streaming
	if err := h.aiService.ProcessStreamChat(r.Context(), chatRequest.Messages, fact, w); err != nil {
		// Error occurred during streaming, try to send an error message
		fmt.Printf("Error in AI streaming: %v\n", err)
		
		// Try to send an error message if possible
		fmt.Fprintf(w, "data: I encountered an error while processing your request: %s\n\n", err.Error())
		w.(http.Flusher).Flush()
		
		// Send completion signal
		fmt.Fprintf(w, "data: [DONE]\n\n")
		w.(http.Flusher).Flush()
	}
}
