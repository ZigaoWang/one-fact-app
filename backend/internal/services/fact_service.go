package services

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/database"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

type FactService struct {
	db *database.Database
}

func NewFactService(db *database.Database) *FactService {
	return &FactService{db: db}
}

func (s *FactService) CreateFact(ctx context.Context, fact *models.Fact) error {
	tx, err := s.db.DB().BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Insert fact
	var factID int
	err = tx.QueryRowContext(ctx, `
		INSERT INTO facts (content, category, source, display_date, active)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`, fact.Content, fact.Category, fact.Source, fact.DisplayDate, fact.Active).Scan(&factID)
	if err != nil {
		return err
	}

	// Insert related articles
	for _, article := range fact.RelatedArticles {
		_, err = tx.ExecContext(ctx, `
			INSERT INTO related_articles (fact_id, title, url, source, snippet)
			VALUES ($1, $2, $3, $4, $5)
		`, factID, article.Title, article.URL, article.Source, article.Snippet)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (s *FactService) GetFactsByCategory(ctx context.Context, category string) ([]models.Fact, error) {
	rows, err := s.db.DB().QueryContext(ctx, `
		SELECT f.id, f.content, f.category, f.source, f.display_date, f.active,
			   ra.id, ra.title, ra.url, ra.source, ra.snippet
		FROM facts f
		LEFT JOIN related_articles ra ON f.id = ra.fact_id
		WHERE f.category = $1 AND f.active = true
		ORDER BY f.display_date DESC
	`, category)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return s.scanFacts(rows)
}

func (s *FactService) GetDailyFact(ctx context.Context) (*models.Fact, error) {
	row := s.db.DB().QueryRowContext(ctx, `
		SELECT f.id, f.content, f.category, f.source, f.display_date, f.active,
			   ra.id, ra.title, ra.url, ra.source, ra.snippet
		FROM facts f
		LEFT JOIN related_articles ra ON f.id = ra.fact_id
		WHERE f.active = true AND f.display_date <= $1
		ORDER BY f.display_date DESC
		LIMIT 1
	`, time.Now())

	facts, err := s.scanFact(row)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("no fact found")
		}
		return nil, err
	}

	return facts, nil
}

func (s *FactService) GetDailyFactByCategory(ctx context.Context, category string) (*models.Fact, error) {
	// Get today's date in UTC
	now := time.Now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	
	row := s.db.DB().QueryRowContext(ctx, `
		SELECT f.id, f.content, f.category, f.source, f.display_date, f.active,
			   ra.id, ra.title, ra.url, ra.source, ra.snippet
		FROM facts f
		LEFT JOIN related_articles ra ON f.id = ra.fact_id
		WHERE f.category = $1 AND f.active = true 
		AND DATE(f.display_date) = DATE($2)
		ORDER BY f.display_date DESC
		LIMIT 1
	`, category, today)

	fact, err := s.scanFact(row)
	if err != nil {
		if err == sql.ErrNoRows {
			// If no fact for today, get the most recent one
			row = s.db.DB().QueryRowContext(ctx, `
				SELECT f.id, f.content, f.category, f.source, f.display_date, f.active,
					   ra.id, ra.title, ra.url, ra.source, ra.snippet
				FROM facts f
				LEFT JOIN related_articles ra ON f.id = ra.fact_id
				WHERE f.category = $1 AND f.active = true
				ORDER BY f.display_date DESC
				LIMIT 1
			`, category)
			
			fact, err = s.scanFact(row)
			if err != nil {
				if err == sql.ErrNoRows {
					return nil, errors.New("no fact found for category: " + category)
				}
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	return fact, nil
}

func (s *FactService) GetRandomFact(ctx context.Context) (*models.Fact, error) {
	row := s.db.DB().QueryRowContext(ctx, `
		SELECT f.id, f.content, f.category, f.source, f.display_date, f.active,
			   ra.id, ra.title, ra.url, ra.source, ra.snippet
		FROM facts f
		LEFT JOIN related_articles ra ON f.id = ra.fact_id
		WHERE f.active = true
		ORDER BY RANDOM()
		LIMIT 1
	`)

	facts, err := s.scanFact(row)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("no fact found")
		}
		return nil, err
	}

	return facts, nil
}

func (s *FactService) scanFacts(rows *sql.Rows) ([]models.Fact, error) {
	facts := make(map[int]*models.Fact)

	for rows.Next() {
		var fact models.Fact
		var article models.RelatedArticle
		var articleID sql.NullInt64
		var articleTitle, articleURL, articleSource, articleSnippet sql.NullString

		err := rows.Scan(
			&fact.ID, &fact.Content, &fact.Category, &fact.Source, &fact.DisplayDate, &fact.Active,
			&articleID, &articleTitle, &articleURL, &articleSource, &articleSnippet,
		)
		if err != nil {
			return nil, err
		}

		if existingFact, ok := facts[fact.ID]; ok {
			if articleID.Valid {
				article = models.RelatedArticle{
					ID:      int(articleID.Int64),
					Title:   articleTitle.String,
					URL:     articleURL.String,
					Source:  articleSource.String,
					Snippet: articleSnippet.String,
				}
				existingFact.RelatedArticles = append(existingFact.RelatedArticles, article)
			}
		} else {
			fact.RelatedArticles = make([]models.RelatedArticle, 0)
			if articleID.Valid {
				article = models.RelatedArticle{
					ID:      int(articleID.Int64),
					Title:   articleTitle.String,
					URL:     articleURL.String,
					Source:  articleSource.String,
					Snippet: articleSnippet.String,
				}
				fact.RelatedArticles = append(fact.RelatedArticles, article)
			}
			facts[fact.ID] = &fact
		}
	}

	result := make([]models.Fact, 0, len(facts))
	for _, fact := range facts {
		result = append(result, *fact)
	}
	return result, nil
}

func (s *FactService) scanFact(row *sql.Row) (*models.Fact, error) {
	var fact models.Fact
	var article models.RelatedArticle
	var articleID sql.NullInt64
	var articleTitle, articleURL, articleSource, articleSnippet sql.NullString

	err := row.Scan(
		&fact.ID, &fact.Content, &fact.Category, &fact.Source, &fact.DisplayDate, &fact.Active,
		&articleID, &articleTitle, &articleURL, &articleSource, &articleSnippet,
	)
	if err != nil {
		return nil, err
	}

	fact.RelatedArticles = make([]models.RelatedArticle, 0)
	if articleID.Valid {
		article = models.RelatedArticle{
			ID:      int(articleID.Int64),
			Title:   articleTitle.String,
			URL:     articleURL.String,
			Source:  articleSource.String,
			Snippet: articleSnippet.String,
		}
		fact.RelatedArticles = append(fact.RelatedArticles, article)
	}

	return &fact, nil
}

func (s *FactService) UpdateFact(ctx context.Context, id string, fact *models.Fact) error {
	_, err := s.db.DB().ExecContext(ctx, `
		UPDATE facts
		SET content = $1, category = $2, source = $3, display_date = $4, active = $5
		WHERE id = $6
	`, fact.Content, fact.Category, fact.Source, fact.DisplayDate, fact.Active, id)
	return err
}

func (s *FactService) DeleteFact(ctx context.Context, id string) error {
	_, err := s.db.DB().ExecContext(ctx, `
		DELETE FROM facts
		WHERE id = $1
	`, id)
	return err
}

// InsertInitialFacts inserts a set of initial facts if they don't exist
func (s *FactService) InsertInitialFacts(ctx context.Context) error {
	log.Println("Starting to insert initial facts...")

	// Science Facts
	scienceFacts := []models.Fact{
		{
			Content:     "The speed of light in a vacuum is exactly 299,792,458 meters per second.",
			Category:    "Science",
			Source:     "Physics Facts",
			DisplayDate: time.Now(),
			Active:     true,
		},
		{
			Content:     "DNA, which contains our genetic code, is a double helix structure first described by Watson and Crick in 1953.",
			Category:    "Science",
			Source:     "Biology Facts",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:     true,
		},
		{
			Content:     "The human brain contains approximately 86 billion neurons.",
			Category:    "Science",
			Source:     "Neuroscience Facts",
			DisplayDate: time.Now().Add(48 * time.Hour),
			Active:     true,
		},
	}

	// History Facts
	historyFacts := []models.Fact{
		{
			Content:     "The Great Wall of China construction began over 2,000 years ago during the Spring and Autumn Period.",
			Category:    "History",
			Source:     "Ancient History Facts",
			DisplayDate: time.Now(),
			Active:     true,
		},
		{
			Content:     "The printing press was invented by Johannes Gutenberg around 1440, revolutionizing communication.",
			Category:    "History",
			Source:     "Medieval History Facts",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:     true,
		},
	}

	// Space Facts
	spaceFacts := []models.Fact{
		{
			Content:     "Mars has two moons: Phobos and Deimos.",
			Category:    "Space",
			Source:     "Planetary Facts",
			DisplayDate: time.Now(),
			Active:     true,
		},
		{
			Content:     "A day on Venus is longer than its year. It takes Venus 243 Earth days to rotate on its axis.",
			Category:    "Space",
			Source:     "Solar System Facts",
			DisplayDate: time.Now().Add(24 * time.Hour),
			Active:     true,
		},
	}

	// Insert all facts
	allFacts := append(append(scienceFacts, historyFacts...), spaceFacts...)
	for _, fact := range allFacts {
		// Check if fact already exists
		exists, err := s.factExists(ctx, fact.Content)
		if err != nil {
			log.Printf("Error checking if fact exists: %v", err)
			continue
		}

		if !exists {
			log.Printf("Inserting new fact: %s", fact.Content)
			if err := s.CreateFact(ctx, &fact); err != nil {
				log.Printf("Error creating fact: %v", err)
				continue
			}
			log.Printf("Successfully inserted fact: %s", fact.Content)
		} else {
			log.Printf("Fact already exists: %s", fact.Content)
		}
	}

	log.Println("Finished inserting initial facts")
	return nil
}

func (s *FactService) factExists(ctx context.Context, content string) (bool, error) {
	var count int
	query := `SELECT COUNT(*) FROM facts WHERE content = $1`
	err := s.db.GetDB().QueryRowContext(ctx, query, content).Scan(&count)
	if err != nil {
		return false, fmt.Errorf("error checking if fact exists: %v", err)
	}
	return count > 0, nil
}
