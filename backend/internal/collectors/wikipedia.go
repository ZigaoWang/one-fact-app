package collectors

import (
	"context"
	"fmt"
	"math/rand"
	"strings"
	"time"
)

// WikipediaSource implements the Source interface for Wikipedia
type WikipediaSource struct {
	BaseSource
}

type wikipediaCategory struct {
	Title string `json:"title"`
}

type wikipediaResponse struct {
	Query struct {
		Pages map[string]struct {
			Title      string             `json:"title"`
			Extract    string            `json:"extract"`
			Categories []wikipediaCategory `json:"categories"`
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
	// Define categories we want to fetch from
	categories := []string{
		"Science",
		"Technology",
		"History",
		"Geography",
		"Arts",
		"Culture",
		"Sports",
		"Entertainment",
		"Politics",
		"Business",
		"Education",
		"Health",
		"Environment",
	}

	var facts []RawFact
	for _, cat := range categories {
		// First, get pages from the category
		var catResponse struct {
			Query struct {
				Categorymembers []struct {
					Title string `json:"title"`
				} `json:"categorymembers"`
			} `json:"query"`
		}

		catURL := fmt.Sprintf("%s?action=query&format=json&list=categorymembers&cmtitle=Category:%s&cmlimit=50",
			w.baseURL, cat)

		if err := w.FetchJSON(ctx, catURL, &catResponse); err != nil {
			continue // Skip this category if there's an error
		}

		// Get random pages from this category
		if len(catResponse.Query.Categorymembers) > 0 {
			// Get 2-3 random pages from each category
			numPages := 2 + rand.Intn(2) // 2 or 3 pages
			for i := 0; i < numPages && i < len(catResponse.Query.Categorymembers); i++ {
				page := catResponse.Query.Categorymembers[i]

				// Get page content
				var pageResponse wikipediaResponse
				pageURL := fmt.Sprintf("%s?action=query&format=json&prop=extracts|categories&exintro=1&explaintext=1&titles=%s",
					w.baseURL, strings.ReplaceAll(page.Title, " ", "_"))

				if err := w.FetchJSON(ctx, pageURL, &pageResponse); err != nil {
					continue
				}

				// Process each page
				for _, pageContent := range pageResponse.Query.Pages {
					// Skip if extract is too short or too long
					if len(pageContent.Extract) < 50 || len(pageContent.Extract) > 500 {
						continue
					}

					// Clean up the extract
					content := strings.TrimSpace(pageContent.Extract)
					if !strings.HasSuffix(content, ".") {
						content += "."
					}

					// Extract categories
					pageCats := make([]string, 0)
					for _, pageCat := range pageContent.Categories {
						catName := strings.TrimPrefix(pageCat.Title, "Category:")
						catName = strings.Trim(catName, " ")
						if catName != "" {
							pageCats = append(pageCats, catName)
						}
					}

					fact := RawFact{
						Content:  content,
						Source:   "Wikipedia",
						Category: cat, // Use the main category we're currently processing
						Tags:     pageCats,
						URLs: []string{
							fmt.Sprintf("https://en.wikipedia.org/wiki/%s", strings.ReplaceAll(pageContent.Title, " ", "_")),
						},
						Metadata: map[string]string{
							"title": pageContent.Title,
						},
						CollectedAt: time.Now(),
					}
					facts = append(facts, fact)
				}
			}
		}
	}

	return facts, nil
}
