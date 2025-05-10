package repositories

import (
	"log"

	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

type BookmarkRepository struct {
	ur UrlRepository
}

func (b *BookmarkRepository) FindByUserID(userID uint) ([]*models.Bookmark, error) {
	var conn = data.GetDB()
	var bookmarks []*models.Bookmark

	// find all bookmarks by user id
	result := conn.Preload("Url").Where("user_id = ?", userID).Find(&bookmarks)

	if result.Error != nil {
		return nil, result.Error
	}

	return bookmarks, nil
}

func (b *BookmarkRepository) Create(bookmark *models.Bookmark, user models.User, url string) error {
	var conn = data.GetDB()

	log.Println(b.ur)

	existingUrl, err := b.ur.FindOrCreate(url)
	if err != nil {
		return err
	}

	bookmark.UrlID = existingUrl.ID
	bookmark.UserID = user.ID

	result := conn.Create(bookmark)

	return result.Error
}
