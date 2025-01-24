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
		host = "one-fact-db-new.internal"  // Use internal hostname for Fly.io
	}
	log.Printf("Using database host: %s", host)
	
	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	log.Printf("Using database port: %s", port)
	
	user := os.Getenv("DB_USER")
	if user == "" {
		user = "one_fact_backend"
	}
	log.Printf("Using database user: %s", user)
	
	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "fAgtBitapVGdU7M"
	}
	
	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "one_fact_backend"
	}
	log.Printf("Using database name: %s", dbname)

	// Create connection string
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	
	log.Printf("Attempting to connect to database...")
	
	// Connect to database
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Printf("Error opening database: %v", err)
		return nil, fmt.Errorf("error opening database: %v", err)
	}

	// Test the connection
	err = db.Ping()
	if err != nil {
		log.Printf("Error pinging database: %v", err)
		return nil, fmt.Errorf("error pinging database: %v", err)
	}

	log.Printf("Successfully connected to database")

	database := &Database{db: db}

	// Create tables if they don't exist
	if err := database.createTables(); err != nil {
		log.Printf("Error creating tables: %v", err)
		return nil, fmt.Errorf("error creating tables: %v", err)
	}

	log.Printf("Database tables created/verified successfully")

	return database, nil
}

func (d *Database) createTables() error {
	log.Printf("Creating/verifying database tables...")
	
	// Create facts table
	_, err := d.db.Exec(`
		CREATE TABLE IF NOT EXISTS facts (
			id SERIAL PRIMARY KEY,
			content TEXT NOT NULL,
			category VARCHAR(50) NOT NULL,
			source VARCHAR(100) NOT NULL,
			active BOOLEAN DEFAULT true,
			display_date DATE NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("error creating facts table: %v", err)
	}

	log.Printf("Facts table created/verified")

	// Create related_articles table
	_, err = d.db.Exec(`
		CREATE TABLE IF NOT EXISTS related_articles (
			id SERIAL PRIMARY KEY,
			fact_id INTEGER REFERENCES facts(id),
			title VARCHAR(200) NOT NULL,
			url TEXT NOT NULL,
			source VARCHAR(100) NOT NULL,
			snippet TEXT,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("error creating related_articles table: %v", err)
	}

	log.Printf("Related articles table created/verified")
	return nil
}

func (d *Database) DB() *sql.DB {
	return d.db
}

func (d *Database) GetDB() *sql.DB {
	return d.db
}

func (d *Database) Close() error {
	return d.db.Close()
}
