package repositories

import (
	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

type UrlRepository struct{}

// first or create
func (u *UrlRepository) FindOrCreate(url string) (*models.Url, error) {
	var conn = data.GetDB()
	var model models.Url

	// find url by id
	result := conn.Where("url = ?", url).Limit(1).Find(&model)

	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		// create the URL if it doesn't exist
		model = models.Url{Url: url}
		result = conn.Create(&model)
		if result.Error != nil {
			return nil, result.Error
		}
	}

	return &model, nil
}
