package models

import (
	"time"

	"gorm.io/gorm"
)

type Category string

const (
	CategoryScience     Category = "Science"
	CategoryHistory     Category = "History"
	CategoryTechnology  Category = "Technology"
	CategorySpace       Category = "Space"
	CategoryNature      Category = "Nature"
	CategoryArt        Category = "Art"
	CategoryLiterature Category = "Literature"
)

type Fact struct {
	gorm.Model
	Content        string         `json:"content" gorm:"not null"`
	Category       Category       `json:"category" gorm:"not null"`
	Source         string         `json:"source" gorm:"not null"`
	URL            *string        `json:"url,omitempty"`
	DisplayDate    time.Time      `json:"displayDate" gorm:"not null;uniqueIndex"`
	Active         bool           `json:"active" gorm:"default:true"`
	RelatedArticles []RelatedArticle `json:"relatedArticles" gorm:"foreignKey:FactID"`
}

type RelatedArticle struct {
	gorm.Model
	FactID    uint   `json:"-" gorm:"not null"`
	Title     string `json:"title" gorm:"not null"`
	URL       string `json:"url" gorm:"not null"`
	Source    string `json:"source" gorm:"not null"`
	ImageURL  *string `json:"imageUrl,omitempty"`
	Snippet   string `json:"snippet" gorm:"not null"`
}
