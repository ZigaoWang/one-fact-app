package models

import (
	"encoding/json"
	"time"
)

// Fact represents a single fact in the database
type Fact struct {
	ID             int               `json:"ID"`
	Content        string           `json:"content"`
	Category       string           `json:"category"`
	Source         string           `json:"source"`
	URL            *string          `json:"url,omitempty"`
	DisplayDate    time.Time        `json:"displayDate,omitempty"`
	Active         bool             `json:"active"`
	RelatedArticles []RelatedArticle `json:"relatedArticles"`
}

// MarshalJSON implements custom JSON marshaling for Fact
func (f Fact) MarshalJSON() ([]byte, error) {
	type Alias Fact
	return json.Marshal(&struct {
		Alias
		DisplayDate string `json:"displayDate"`
	}{
		Alias:       Alias(f),
		DisplayDate: f.DisplayDate.Format(time.RFC3339),
	})
}

// UnmarshalJSON implements custom JSON unmarshaling for Fact
func (f *Fact) UnmarshalJSON(data []byte) error {
	type Alias Fact
	aux := &struct {
		*Alias
		DisplayDate string `json:"displayDate"`
	}{
		Alias: (*Alias)(f),
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	if aux.DisplayDate != "" {
		date, err := time.Parse(time.RFC3339, aux.DisplayDate)
		if err != nil {
			return err
		}
		f.DisplayDate = date
	}
	return nil
}

// RelatedArticle represents an article related to a fact
type RelatedArticle struct {
	ID       int     `json:"ID"`
	Title    string  `json:"title"`
	URL      string  `json:"url"`
	Source   string  `json:"source"`
	ImageURL *string `json:"imageUrl,omitempty"`
	Snippet  string  `json:"snippet"`
}
