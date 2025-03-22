package counter

import (
	"math/rand"
	"strconv"

	"gorm.io/gorm"
)

type DatabaseRepository struct {
	db *gorm.DB
}

func NewDatabaseRepository(db *gorm.DB) *DatabaseRepository {
	return &DatabaseRepository{
		db: db,
	}
}

func (r *DatabaseRepository) Create(counter *Counter) error {
	if counter.ID == "" {
		counter.ID = strconv.Itoa(rand.Int())
	}

	result := r.db.Create(counter)
	return result.Error
}

func (r *DatabaseRepository) Get(id string) (*Counter, error) {
	var counter *Counter
	result := r.db.Limit(1).Find(&counter, "id = ?", id)

	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return counter, nil
}

func (r *DatabaseRepository) Update(counter *Counter) error {
	result := r.db.Save(counter)
	return result.Error
}

func (r *DatabaseRepository) Delete(id string) error {
	result := r.db.Delete(&Counter{}, "id = ?", id)
	return result.Error
}
