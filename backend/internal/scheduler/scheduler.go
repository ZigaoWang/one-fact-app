package scheduler

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/ZigaoWang/one-fact-app/backend/internal/collectors"
	"github.com/ZigaoWang/one-fact-app/backend/internal/processors"
	"go.mongodb.org/mongo-driver/mongo"
)

// Scheduler manages automated fact collection and processing
type Scheduler struct {
	sources    []collectors.Source
	processor  *processors.Processor
	collection *mongo.Collection
	interval   time.Duration
	mutex      sync.Mutex
	running    bool
}

// NewScheduler creates a new scheduler instance
func NewScheduler(collection *mongo.Collection) *Scheduler {
	return &Scheduler{
		sources: []collectors.Source{
			collectors.NewWikipediaSource(),
			// Add more sources here
		},
		processor:  processors.NewProcessor(),
		collection: collection,
		interval:   6 * time.Hour, // Collect facts every 6 hours
	}
}

// Start begins the automated fact collection process
func (s *Scheduler) Start(ctx context.Context) error {
	s.mutex.Lock()
	if s.running {
		s.mutex.Unlock()
		return nil
	}
	s.running = true
	s.mutex.Unlock()

	ticker := time.NewTicker(s.interval)
	defer ticker.Stop()

	// Initial collection
	if err := s.CollectFacts(ctx); err != nil {
		log.Printf("Error in initial fact collection: %v", err)
	}

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			if err := s.CollectFacts(ctx); err != nil {
				log.Printf("Error collecting facts: %v", err)
			}
		}
	}
}

// CollectFacts collects facts from all sources
func (s *Scheduler) CollectFacts(ctx context.Context) error {
	var wg sync.WaitGroup
	factsChan := make(chan *processors.ProcessedFact, 100)
	errorsChan := make(chan error, len(s.sources))

	// Collect facts from all sources concurrently
	for _, source := range s.sources {
		wg.Add(1)
		go func(src collectors.Source) {
			defer wg.Done()
			
			rawFacts, err := src.GetFacts(ctx)
			if err != nil {
				errorsChan <- err
				return
			}

			// Process each fact
			for _, raw := range rawFacts {
				fact, err := s.processor.Process(ctx, raw)
				if err != nil {
					log.Printf("Error processing fact from %s: %v", src.Name(), err)
					continue
				}
				if fact != nil {
					factsChan <- fact
				}
			}
		}(source)
	}

	// Wait for all goroutines to finish and close channels
	go func() {
		wg.Wait()
		close(factsChan)
		close(errorsChan)
	}()

	// Store facts in MongoDB
	var errs []error
	for fact := range factsChan {
		if _, err := s.collection.InsertOne(ctx, fact); err != nil {
			errs = append(errs, fmt.Errorf("storing fact: %w", err))
		}
	}

	// Check for errors from sources
	for err := range errorsChan {
		errs = append(errs, err)
	}

	if len(errs) > 0 {
		return fmt.Errorf("collecting facts: %v", errs)
	}

	return nil
}

// Stop stops the scheduler
func (s *Scheduler) Stop() {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	s.running = false
}
