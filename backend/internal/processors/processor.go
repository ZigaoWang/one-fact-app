package processors

import (
	"context"
	"strings"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/collectors"
)

// ProcessedFact represents a fact that has been validated and enriched
type ProcessedFact struct {
	ID          string            `json:"id" bson:"_id,omitempty"`
	Content     string            `json:"content" bson:"content"`
	Source      string            `json:"source" bson:"source"`
	Category    string            `json:"category" bson:"category"`
	Tags        []string          `json:"tags" bson:"tags"`
	URLs        []string          `json:"related_urls" bson:"related_urls"`
	Metadata    map[string]string `json:"metadata" bson:"metadata"`
	Verified    bool             `json:"verified" bson:"verified"`
	Score       float64          `json:"score" bson:"score"`
	CreatedAt   time.Time        `json:"created_at" bson:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at" bson:"updated_at"`
	PublishDate time.Time        `json:"publish_date" bson:"publish_date"`
}

// Processor handles fact validation and enrichment
type Processor struct {
	minLength     int
	maxLength     int
	minScore      float64
	bannedWords   []string
	requiredWords []string
}

// NewProcessor creates a new fact processor
func NewProcessor() *Processor {
	return &Processor{
		minLength: 50,
		maxLength: 500,
		minScore:  0.7,
		bannedWords: []string{
			"died", "killed", "death", "murder", "suicide",
			"explicit", "nsfw", "graphic",
		},
		requiredWords: []string{
			"the", "is", "are", "was", "were",
		},
	}
}

// Process validates and enriches a raw fact
func (p *Processor) Process(ctx context.Context, raw collectors.RawFact) (*ProcessedFact, error) {
	// Basic validation
	if !p.validateLength(raw.Content) {
		return nil, nil
	}

	if !p.validateContent(raw.Content) {
		return nil, nil
	}

	// Calculate fact quality score
	score := p.calculateScore(raw)
	if score < p.minScore {
		return nil, nil
	}

	// Create processed fact with normalized fields
	now := time.Now()
	fact := &ProcessedFact{
		Content:     raw.Content,
		Source:      raw.Source,
		Category:    p.normalizeCategory(raw.Category),
		Tags:        p.normalizeTags(raw.Tags),
		URLs:        raw.URLs,
		Metadata:    raw.Metadata,
		Verified:    true,
		Score:       score,
		CreatedAt:   now,
		UpdatedAt:   now,
		PublishDate: now.AddDate(0, 0, 1), // Schedule for tomorrow
	}

	return fact, nil
}

func (p *Processor) validateLength(content string) bool {
	length := len(content)
	return length >= p.minLength && length <= p.maxLength
}

func (p *Processor) validateContent(content string) bool {
	content = strings.ToLower(content)
	
	// Check for banned words
	for _, word := range p.bannedWords {
		if strings.Contains(content, word) {
			return false
		}
	}

	// Check for required words
	hasRequiredWord := false
	for _, word := range p.requiredWords {
		if strings.Contains(content, word) {
			hasRequiredWord = true
			break
		}
	}

	return hasRequiredWord
}

func (p *Processor) calculateScore(raw collectors.RawFact) float64 {
	var score float64 = 1.0

	// Content length score (0.8 - 1.2)
	contentLength := len(raw.Content)
	if contentLength >= 200 && contentLength <= 300 {
		score += 0.2
	} else if contentLength < 100 || contentLength > 400 {
		score -= 0.2
	}

	// Category score (0 - 0.2)
	if raw.Category != "" {
		score += 0.1
	}

	// Tags score (0 - 0.2)
	if len(raw.Tags) > 0 {
		score += 0.1
		if len(raw.Tags) >= 3 {
			score += 0.1
		}
	}

	// URLs score (0 - 0.2)
	if len(raw.URLs) > 0 {
		score += 0.2
	}

	// Metadata score (0 - 0.2)
	if len(raw.Metadata) > 0 {
		score += 0.1
		if len(raw.Metadata) >= 3 {
			score += 0.1
		}
	}

	return score
}

func (p *Processor) normalizeCategory(category string) string {
	// Map of Wikipedia categories to our standard categories
	categoryMap := map[string]string{
		"All Article Disambiguation Pages": "General",
		"All disambiguation pages": "General",
		"Disambiguation pages": "General",
		"Living people": "People",
		"Science": "Science",
		"Technology": "Technology",
		"History": "History",
		"Geography": "Geography",
		"Arts": "Arts",
		"Culture": "Culture",
		"Sports": "Sports",
		"Entertainment": "Entertainment",
		"Politics": "Politics",
		"Business": "Business",
		"Education": "Education",
		"Health": "Health",
		"Environment": "Environment",
		"Space": "Science",
		"Physics": "Science",
		"Chemistry": "Science",
		"Biology": "Science",
		"Mathematics": "Science",
		"Computer Science": "Technology",
		"Engineering": "Technology",
		"Internet": "Technology",
		"Software": "Technology",
		"Hardware": "Technology",
		"Artificial Intelligence": "Technology",
		"Robotics": "Technology",
	}

	// Clean up category name
	category = strings.TrimSpace(category)
	category = strings.TrimPrefix(category, "Category:")

	// Check if we have a direct mapping
	if mapped, ok := categoryMap[category]; ok {
		return mapped
	}

	// Check if category contains any of our standard categories
	for _, standardCat := range []string{"Science", "Technology", "History", "Geography", "Arts", "Culture", "Sports", "Entertainment", "Politics", "Business", "Education", "Health", "Environment"} {
		if strings.Contains(category, standardCat) {
			return standardCat
		}
	}

	// Default to General if no match found
	return "General"
}

func (p *Processor) normalizeTags(tags []string) []string {
	normalizedTags := make([]string, 0, len(tags))
	seenTags := make(map[string]bool)

	for _, tag := range tags {
		// Clean up tag
		tag = strings.TrimSpace(tag)
		tag = strings.TrimPrefix(tag, "Category:")
		tag = strings.ToLower(tag)

		// Skip empty or already seen tags
		if tag == "" || seenTags[tag] {
			continue
		}

		normalizedTags = append(normalizedTags, tag)
		seenTags[tag] = true
	}

	return normalizedTags
}
