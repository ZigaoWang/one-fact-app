package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	FactsRequested = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "one_fact_facts_requested_total",
		Help: "The total number of facts requested",
	}, []string{"category", "type"})

	FactsFetched = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "one_fact_facts_fetched_total",
		Help: "The total number of facts fetched from external sources",
	}, []string{"source"})

	APILatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "one_fact_api_latency_seconds",
		Help:    "API endpoint latency in seconds",
		Buckets: prometheus.DefBuckets,
	}, []string{"endpoint"})

	DatabaseLatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "one_fact_db_latency_seconds",
		Help:    "Database operation latency in seconds",
		Buckets: prometheus.DefBuckets,
	}, []string{"operation"})

	ErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "one_fact_errors_total",
		Help: "Total number of errors encountered",
	}, []string{"type"})
)
