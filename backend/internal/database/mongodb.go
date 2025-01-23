package database

import (
	"sync"
)

// Database represents our in-memory database
type Database struct {
	sync.RWMutex
	facts map[string]interface{}
}

// NewDatabase creates a new in-memory database
func NewDatabase(_, _ string) (*Database, error) {
	return &Database{
		facts: make(map[string]interface{}),
	}, nil
}

// GetCollection returns the in-memory collection
func (d *Database) GetCollection(name string) interface{} {
	return d
}

// Close is a no-op for in-memory database
func (d *Database) Close() error {
	return nil
}
