package counter

import (
	"math/rand"
	"strconv"
	"sync"
)

type MemoryRepository struct {
	counters map[string]Counter
	lock     *sync.RWMutex
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		counters: map[string]Counter{},
		lock:     &sync.RWMutex{},
	}
}

func (r *MemoryRepository) Create(counter *Counter) error {
	r.lock.RLock()
	defer r.lock.RUnlock()

	if counter.ID == "" {
		counter.ID = strconv.Itoa(rand.Int())
	}

	r.counters[counter.ID] = *counter
	return nil
}

func (r *MemoryRepository) Get(id string) (*Counter, error) {
	if counter, ok := r.counters[id]; ok {
		return &counter, nil
	}

	return nil, nil
}

func (r *MemoryRepository) Update(counter *Counter) error {
	r.lock.RLock()
	defer r.lock.RUnlock()

	r.counters[counter.ID] = *counter
	return nil
}

func (r *MemoryRepository) Delete(id string) error {
	r.lock.RLock()
	defer r.lock.RUnlock()

	delete(r.counters, id)
	return nil
}
