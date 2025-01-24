package services

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

type FactFetcher struct {
	factService *FactService
	client      *http.Client
}

func NewFactFetcher(factService *FactService) *FactFetcher {
	return &FactFetcher{
		factService: factService,
		client:      &http.Client{Timeout: 10 * time.Second},
	}
}

type WikipediaResponse struct {
	Title   string `json:"title"`
	Extract string `json:"extract"`
}

type NumbersAPIResponse struct {
	Text string `json:"text"`
	Type string `json:"type"`
}

type TodayInHistoryResponse struct {
	Events []struct {
		Year string `json:"year"`
		Text string `json:"text"`
	} `json:"events"`
}

type FunFactResponse struct {
	Id     string `json:"id"`
	Text   string `json:"text"`
	Source string `json:"source"`
}

func (f *FactFetcher) FetchAndStoreFacts(ctx context.Context) error {
	sources := []func(context.Context) error{
		f.fetchFromWikipedia,
		f.fetchFromNumbersAPI,
		f.fetchFromTodayInHistory,
		f.fetchFromFunFactAPI,
		f.fetchFromNASAAPI,
	}

	for _, source := range sources {
		if err := source(ctx); err != nil {
			// Log error but continue with other sources
			fmt.Printf("Error fetching from source: %v\n", err)
		}
	}

	return nil
}

func (f *FactFetcher) fetchFromWikipedia(ctx context.Context) error {
	// Make API request
	resp, err := f.client.Get("https://en.wikipedia.org/api/rest_v1/page/random/summary")
	if err != nil {
		return fmt.Errorf("error fetching from Wikipedia: %v", err)
	}
	defer resp.Body.Close()

	var wikiResp WikipediaResponse
	if err := json.NewDecoder(resp.Body).Decode(&wikiResp); err != nil {
		return fmt.Errorf("error decoding Wikipedia response: %v", err)
	}

	// Extract first 100 characters or less for the content
	content := wikiResp.Extract
	if len(content) > 100 {
		content = content[:100] + "..."
	}

	// Create fact
	fact := &models.Fact{
		Content:     content,
		Category:    "General",
		Source:     "Wikipedia",
		DisplayDate: time.Now().Add(24 * time.Hour),
		Active:     true,
	}

	if err := f.factService.CreateFact(ctx, fact); err != nil {
		return fmt.Errorf("error creating fact: %v", err)
	}

	return nil
}

func (f *FactFetcher) fetchFromNumbersAPI(ctx context.Context) error {
	categories := []string{"math", "trivia", "date", "year"}

	for _, category := range categories {
		url := fmt.Sprintf("http://numbersapi.com/random/%s?json", category)
		
		resp, err := f.client.Get(url)
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		var numResp NumbersAPIResponse
		if err := json.NewDecoder(resp.Body).Decode(&numResp); err != nil {
			return err
		}

		fact := &models.Fact{
			Content:     numResp.Text,
			Category:    numResp.Type,
			Source:      "Numbers API",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:      true,
		}

		if err := f.factService.CreateFact(ctx, fact); err != nil {
			return err
		}
	}

	return nil
}

func (f *FactFetcher) fetchFromTodayInHistory(ctx context.Context) error {
	// Get today's date
	now := time.Now()
	month := now.Month()
	day := now.Day()

	// Make API request
	url := fmt.Sprintf("https://history.muffinlabs.com/date/%d/%d", int(month), day)
	resp, err := f.client.Get(url)
	if err != nil {
		return fmt.Errorf("error fetching today in history: %v", err)
	}
	defer resp.Body.Close()

	var response TodayInHistoryResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return fmt.Errorf("error decoding response: %v", err)
	}

	// Guard against empty events
	if len(response.Events) == 0 {
		return nil
	}

	// Get up to 5 random events
	numEvents := len(response.Events)
	if numEvents > 5 {
		numEvents = 5
	}

	// Create facts from events
	for i := 0; i < numEvents; i++ {
		event := response.Events[i]
		fact := &models.Fact{
			Content:     fmt.Sprintf("On this day in %s: %s", event.Year, event.Text),
			Category:    "History",
			Source:     "Today in History API",
			DisplayDate: now,
			Active:     true,
		}

		if err := f.factService.CreateFact(ctx, fact); err != nil {
			return fmt.Errorf("error creating fact: %v", err)
		}
	}

	return nil
}

func (f *FactFetcher) fetchFromFunFactAPI(ctx context.Context) error {
	url := "https://uselessfacts.jsph.pl/random.json?language=en"

	resp, err := f.client.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var funResp FunFactResponse
	if err := json.NewDecoder(resp.Body).Decode(&funResp); err != nil {
		return err
	}

	fact := &models.Fact{
		Content:     funResp.Text,
		Category:    "Fun Facts",
		Source:      funResp.Source,
		DisplayDate: time.Now().Add(24 * time.Hour),
		Active:      true,
	}

	if err := f.factService.CreateFact(ctx, fact); err != nil {
		return err
	}

	return nil
}

func (f *FactFetcher) fetchFromNASAAPI(ctx context.Context) error {
	url := "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"

	resp, err := f.client.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var nasaResp struct {
		Title       string `json:"title"`
		Explanation string `json:"explanation"`
		URL         string `json:"url"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&nasaResp); err != nil {
		return err
	}

	fact := &models.Fact{
		Content:     nasaResp.Explanation,
		Category:    "Space",
		Source:      "NASA",
		DisplayDate: time.Now().Add(24 * time.Hour),
		Active:      true,
		RelatedArticles: []models.RelatedArticle{
			{
				Title:   nasaResp.Title,
				URL:     nasaResp.URL,
				Source:  "NASA APOD",
				Snippet: nasaResp.Explanation[:100] + "...",
			},
		},
	}

	if err := f.factService.CreateFact(ctx, fact); err != nil {
		return err
	}

	return nil
}
