package collectors

import (
	"context"
	"fmt"
	"strings"
	"time"
)

// WikipediaSource implements the Source interface for Wikipedia
type WikipediaSource struct {
	BaseSource
}

type wikipediaResponse struct {
	Query struct {
		Pages map[string]struct {
			Title    string   `json:"title"`
			Extract  string   `json:"extract"`
			Category []string `json:"categories"`
		} `json:"pages"`
	} `json:"query"`
}

// NewWikipediaSource creates a new Wikipedia source
func NewWikipediaSource() *WikipediaSource {
	return &WikipediaSource{
		BaseSource: NewBaseSource("https://en.wikipedia.org/w/api.php", ""),
	}
}

// Name returns the source name
func (w *WikipediaSource) Name() string {
	return "Wikipedia"
}

// GetFacts fetches random facts from Wikipedia
func (w *WikipediaSource) GetFacts(ctx context.Context) ([]RawFact, error) {
	var response wikipediaResponse
	url := fmt.Sprintf("%s?action=query&format=json&prop=extracts|categories&exintro=1&explaintext=1&generator=random&grnnamespace=0&grnlimit=10",
		w.baseURL)

	if err := w.FetchJSON(ctx, url, &response); err != nil {
		return nil, fmt.Errorf("fetching from Wikipedia: %w", err)
	}

	var facts []RawFact
	for _, page := range response.Query.Pages {
		// Skip if extract is too short or too long
		if len(page.Extract) < 50 || len(page.Extract) > 500 {
			continue
		}

		// Clean up the extract
		content := strings.TrimSpace(page.Extract)
		if !strings.HasSuffix(content, ".") {
			content += "."
		}

		// Extract categories
		categories := make([]string, 0)
		for _, cat := range page.Category {
			// Remove "Category:" prefix and clean up
			cat = strings.TrimPrefix(cat, "Category:")
			cat = strings.Trim(cat, " ")
			if cat != "" {
				categories = append(categories, cat)
			}
		}

		fact := RawFact{
			Content:  content,
			Source:   "Wikipedia",
			Category: "General Knowledge",
			Tags:     categories,
			URLs: []string{
				fmt.Sprintf("https://en.wikipedia.org/wiki/%s", strings.ReplaceAll(page.Title, " ", "_")),
			},
			Metadata: map[string]string{
				"title": page.Title,
			},
			CollectedAt: time.Now(),
		}
		facts = append(facts, fact)
	}

	return facts, nil
}
