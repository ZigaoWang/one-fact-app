package models

import (
	"encoding/json"
	"time"
)

// Fact represents a single fact in the database
type Fact struct {
	ID             int             `json:"id"`
	Content        string          `json:"content"`
	Category       string          `json:"category"`
	Source         string          `json:"source"`
	DisplayDate    time.Time       `json:"displayDate"`
	Active         bool            `json:"active"`
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
	ID      int    `json:"id"`
	Title   string `json:"title"`
	URL     string `json:"url"`
	Source  string `json:"source"`
	Snippet string `json:"snippet"`
}
