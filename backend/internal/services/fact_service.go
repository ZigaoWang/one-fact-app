package services

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"strings"
	"sync"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

type FactService struct {
	sync.RWMutex
	facts map[int]*models.Fact
	lastID int
}

func NewFactService(db interface{}) *FactService {
	return &FactService{
		facts: make(map[int]*models.Fact),
		lastID: 0,
	}
}

// GetDailyFact returns the fact for the current day
func (s *FactService) GetDailyFact(ctx context.Context) (*models.Fact, error) {
	s.RLock()
	defer s.RUnlock()

	today := time.Now().UTC().Truncate(24 * time.Hour)
	
	var todayFacts []*models.Fact
	for _, fact := range s.facts {
		if fact.DisplayDate.Truncate(24 * time.Hour).Equal(today) && fact.Active {
			todayFacts = append(todayFacts, fact)
		}
	}

	if len(todayFacts) == 0 {
		return nil, errors.New("no fact available for today")
	}

	// Use the day of the year to deterministically select a fact
	// This ensures all users get the same fact on a given day
	dayOfYear := today.YearDay()
	selectedIndex := dayOfYear % len(todayFacts)
	return todayFacts[selectedIndex], nil
}

// GetRandomFact returns a random published fact
func (s *FactService) GetRandomFact(ctx context.Context) (*models.Fact, error) {
	s.RLock()
	defer s.RUnlock()

	var activeFacts []*models.Fact
	for _, fact := range s.facts {
		if fact.Active {
			activeFacts = append(activeFacts, fact)
		}
	}

	if len(activeFacts) == 0 {
		return nil, errors.New("no facts available")
	}

	return activeFacts[rand.Intn(len(activeFacts))], nil
}

// CreateFact creates a new fact
func (s *FactService) CreateFact(ctx context.Context, fact *models.Fact) error {
	s.Lock()
	defer s.Unlock()

	if fact.ID == 0 {
		s.lastID++
		fact.ID = s.lastID
	} else if fact.ID > s.lastID {
		s.lastID = fact.ID
	}
	
	s.facts[fact.ID] = fact
	return nil
}

// UpdateFact updates an existing fact
func (s *FactService) UpdateFact(ctx context.Context, id string, fact *models.Fact) error {
	s.Lock()
	defer s.Unlock()

	factID := 0
	_, err := fmt.Sscanf(id, "%d", &factID)
	if err != nil {
		return errors.New("invalid fact ID")
	}

	if _, exists := s.facts[factID]; !exists {
		return errors.New("fact not found")
	}

	fact.ID = factID
	s.facts[factID] = fact
	return nil
}

// DeleteFact deletes a fact by ID
func (s *FactService) DeleteFact(ctx context.Context, id string) error {
	s.Lock()
	defer s.Unlock()

	factID := 0
	_, err := fmt.Sscanf(id, "%d", &factID)
	if err != nil {
		return errors.New("invalid fact ID")
	}

	if _, exists := s.facts[factID]; !exists {
		return errors.New("fact not found")
	}

	delete(s.facts, factID)
	return nil
}

// GetFactsByCategory returns all facts in a given category
func (s *FactService) GetFactsByCategory(ctx context.Context, category string) ([]*models.Fact, error) {
	s.RLock()
	defer s.RUnlock()

	var categoryFacts []*models.Fact
	searchCategory := strings.ToLower(category)
	
	for _, fact := range s.facts {
		if fact.Active && strings.ToLower(fact.Category) == searchCategory {
			categoryFacts = append(categoryFacts, fact)
		}
	}

	if len(categoryFacts) == 0 {
		return []*models.Fact{}, nil
	}

	// Return all facts in the category
	return categoryFacts, nil
}
