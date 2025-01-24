package collectors

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Source represents a fact source interface
type Source interface {
	GetFacts(ctx context.Context) ([]RawFact, error)
	Name() string
}

// RawFact represents unprocessed fact data from sources
type RawFact struct {
	Content     string            `json:"content"`
	Source      string            `json:"source"`
	Category    string            `json:"category"`
	Tags        []string          `json:"tags"`
	URLs        []string          `json:"urls"`
	Metadata    map[string]string `json:"metadata"`
	CollectedAt time.Time         `json:"collected_at"`
}

// BaseSource provides common functionality for sources
type BaseSource struct {
	client  *http.Client
	baseURL string
	apiKey  string
}

// NewBaseSource creates a new base source with common configuration
func NewBaseSource(baseURL, apiKey string) BaseSource {
	return BaseSource{
		client: &http.Client{
			Timeout: time.Second * 10,
		},
		baseURL: baseURL,
		apiKey:  apiKey,
	}
}

// FetchJSON performs a GET request and unmarshals JSON response
func (s *BaseSource) FetchJSON(ctx context.Context, url string, target interface{}) error {
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("creating request: %w", err)
	}

	if s.apiKey != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", s.apiKey))
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("executing request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	if err := json.NewDecoder(resp.Body).Decode(target); err != nil {
		return fmt.Errorf("decoding response: %w", err)
	}

	return nil
}
