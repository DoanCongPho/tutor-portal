package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	redis "github.com/redis/go-redis/v9"
)

// kvStore is the minimal Redis-shaped key/value interface the auth service
// needs (OTPs + session JTIs — both short-lived with a TTL). Two impls exist:
//   - redisStore: backed by a real Redis (production)
//   - memoryStore: in-process map (dev when Redis isn't running)
//
// The auth service consumes this interface so swapping is invisible.
type kvStore interface {
	Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
	Get(ctx context.Context, key string) ([]byte, error)
	Del(ctx context.Context, key string) error
}

// errKVNotFound is returned by Get when the key is missing or expired.
var errKVNotFound = errors.New("auth/kv: key not found")

// --- redis-backed ---

type redisStore struct {
	client *redis.Client
}

func (r *redisStore) Set(ctx context.Context, key string, value []byte, ttl time.Duration) error {
	return r.client.Set(ctx, key, value, ttl).Err()
}

func (r *redisStore) Get(ctx context.Context, key string) ([]byte, error) {
	b, err := r.client.Get(ctx, key).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, errKVNotFound
	}
	return b, err
}

func (r *redisStore) Del(ctx context.Context, key string) error {
	return r.client.Del(ctx, key).Err()
}

// --- in-memory fallback ---
//
// Lazy expiration on Get is sufficient: OTPs and session JTIs are short-lived
// and the working set is bounded by active users. No background sweep needed.

type memEntry struct {
	value     []byte
	expiresAt time.Time
}

type memoryStore struct {
	mu   sync.Mutex
	data map[string]memEntry
}

func newMemoryStore() *memoryStore {
	return &memoryStore{data: make(map[string]memEntry)}
}

func (m *memoryStore) Set(_ context.Context, key string, value []byte, ttl time.Duration) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	// Defensive copy — callers may reuse the slice.
	cp := make([]byte, len(value))
	copy(cp, value)
	m.data[key] = memEntry{value: cp, expiresAt: time.Now().Add(ttl)}
	return nil
}

func (m *memoryStore) Get(_ context.Context, key string) ([]byte, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	e, ok := m.data[key]
	if !ok {
		return nil, errKVNotFound
	}
	if time.Now().After(e.expiresAt) {
		delete(m.data, key)
		return nil, errKVNotFound
	}
	cp := make([]byte, len(e.value))
	copy(cp, e.value)
	return cp, nil
}

func (m *memoryStore) Del(_ context.Context, key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.data, key)
	return nil
}
