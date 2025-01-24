package processors

import (
	"context"
	"strings"
	"time"

	"github.com/zigaowang/one-fact-app/internal/collectors"
)

// ProcessedFact represents a fact that has been validated and enriched
type ProcessedFact struct {
	ID          string            `json:"id" bson:"_id,omitempty"`
	Content     string            `json:"content"`
	Source      string            `json:"source"`
	Category    string            `json:"category"`
	Tags        []string          `json:"tags"`
	URLs        []string          `json:"urls"`
	Metadata    map[string]string `json:"metadata"`
	Verified    bool              `json:"verified"`
	Score       float64           `json:"score"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
	PublishDate time.Time         `json:"publish_date"`
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

	// Create processed fact
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
	hasRequired := false
	for _, word := range p.requiredWords {
		if strings.Contains(content, word) {
			hasRequired = true
			break
		}
	}

	return hasRequired
}

func (p *Processor) calculateScore(raw collectors.RawFact) float64 {
	score := 1.0

	// Reduce score for very short or very long content
	contentLength := len(raw.Content)
	if contentLength < 100 {
		score *= 0.8
	} else if contentLength > 400 {
		score *= 0.9
	}

	// Boost score for facts with metadata
	if len(raw.Metadata) > 0 {
		score *= 1.1
	}

	// Boost score for facts with URLs
	if len(raw.URLs) > 0 {
		score *= 1.1
	}

	// Boost score for facts with tags
	if len(raw.Tags) > 0 {
		score *= 1.1
	}

	return score
}

func (p *Processor) normalizeCategory(category string) string {
	category = strings.TrimSpace(category)
	if category == "" {
		return "General Knowledge"
	}
	return strings.Title(strings.ToLower(category))
}

func (p *Processor) normalizeTags(tags []string) []string {
	normalized := make([]string, 0, len(tags))
	seen := make(map[string]bool)

	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		tag = strings.ToLower(tag)
		if tag != "" && !seen[tag] {
			normalized = append(normalized, tag)
			seen[tag] = true
		}
	}

	return normalized
}
