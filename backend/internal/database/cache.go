package database

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/ZigaoWang/one-fact-app/backend/internal/config"
	"github.com/ZigaoWang/one-fact-app/backend/internal/models"
)

type Cache struct {
	client *redis.Client
	ttl    time.Duration
}

func NewCache(cfg *config.Config) (*Cache, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cfg.Redis.Host, cfg.Redis.Port),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}

	return &Cache{
		client: client,
		ttl:    cfg.Services.CacheTTL,
	}, nil
}

func (c *Cache) Close() error {
	return c.client.Close()
}

func (c *Cache) SetDailyFact(ctx context.Context, fact *models.Fact) error {
	data, err := json.Marshal(fact)
	if err != nil {
		return err
	}

	key := c.getDailyFactKey()
	return c.client.Set(ctx, key, data, c.ttl).Err()
}

func (c *Cache) GetDailyFact(ctx context.Context) (*models.Fact, error) {
	key := c.getDailyFactKey()
	data, err := c.client.Get(ctx, key).Bytes()
	if err != nil {
		if err == redis.Nil {
			return nil, nil
		}
		return nil, err
	}

	var fact models.Fact
	if err := json.Unmarshal(data, &fact); err != nil {
		return nil, err
	}

	return &fact, nil
}

func (c *Cache) getDailyFactKey() string {
	return fmt.Sprintf("daily_fact:%s", time.Now().Format("2006-01-02"))
}

// IncrementFactServeCount increments the serve count for a fact
func (c *Cache) IncrementFactServeCount(ctx context.Context, factID string) error {
	key := fmt.Sprintf("fact_serve_count:%s", factID)
	return c.client.Incr(ctx, key).Err()
}

// GetFactServeCount gets the serve count for a fact
func (c *Cache) GetFactServeCount(ctx context.Context, factID string) (int64, error) {
	key := fmt.Sprintf("fact_serve_count:%s", factID)
	return c.client.Get(ctx, key).Int64()
}
