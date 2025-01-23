package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

type Database struct {
	db *sql.DB
}

func NewDatabase() (*Database, error) {
	// Get database connection details from environment variables
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "bitter-leaf-3180.flycast"
	}
	
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "postgres"
	}
	
	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "VXb7iAx7Bdbr8rR"
	}
	
	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "postgres"
	}

	// Create connection string
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	// Open database connection
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("error opening database: %v", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("error connecting to the database: %v", err)
	}

	// Create database instance
	database := &Database{
		db: db,
	}

	// Initialize tables
	if err := database.createTables(); err != nil {
		return nil, fmt.Errorf("error creating tables: %v", err)
	}

	return database, nil
}

func (d *Database) createTables() error {
	// Create facts table
	_, err := d.db.Exec(`
		CREATE TABLE IF NOT EXISTS facts (
			id SERIAL PRIMARY KEY,
			content TEXT NOT NULL,
			category VARCHAR(50) NOT NULL,
			source VARCHAR(255) NOT NULL,
			display_date TIMESTAMP NOT NULL,
			active BOOLEAN NOT NULL DEFAULT true,
			created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("error creating facts table: %v", err)
	}

	// Create related_articles table
	_, err = d.db.Exec(`
		CREATE TABLE IF NOT EXISTS related_articles (
			id SERIAL PRIMARY KEY,
			fact_id INTEGER NOT NULL REFERENCES facts(id) ON DELETE CASCADE,
			title VARCHAR(255) NOT NULL,
			url TEXT NOT NULL,
			source VARCHAR(255) NOT NULL,
			snippet TEXT,
			created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("error creating related_articles table: %v", err)
	}

	// Create indexes
	indexes := []string{
		"CREATE INDEX IF NOT EXISTS idx_facts_category ON facts(category)",
		"CREATE INDEX IF NOT EXISTS idx_facts_display_date ON facts(display_date)",
		"CREATE INDEX IF NOT EXISTS idx_facts_active ON facts(active)",
		"CREATE INDEX IF NOT EXISTS idx_related_articles_fact_id ON related_articles(fact_id)",
	}

	for _, idx := range indexes {
		if _, err := d.db.Exec(idx); err != nil {
			return fmt.Errorf("error creating index: %v", err)
		}
	}

	log.Println("Database tables and indexes created successfully")
	return nil
}

func (d *Database) DB() *sql.DB {
	return d.db
}

func (d *Database) Close() error {
	return d.db.Close()
}
