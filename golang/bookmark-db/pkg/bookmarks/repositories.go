package bookmarks

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	"gorm.io/gorm"
)

var Repos struct {
	Bookmark BookmarkRepository
}

func initRepos() {
	Repos.Bookmark = &BookmarkDBRepository{db: databases.DBs.Default}
}

type BookmarkRepository interface {
	CreateBookmark(bookmark *models.Bookmark) error
	UpdateBookmark(bookmark *models.Bookmark) error
	DeleteBookmarkByID(id int) (bool, error)
	GetBookmarksByUserID(userID int) ([]*models.Bookmark, error)
	GetBookmarkByID(id int) (*models.Bookmark, error)
}

type BookmarkDBRepository struct {
	db *gorm.DB
}

func (r *BookmarkDBRepository) CreateBookmark(bookmark *models.Bookmark) error {
	return r.db.Create(bookmark).Error
}

func (r *BookmarkDBRepository) UpdateBookmark(bookmark *models.Bookmark) error {
	return r.db.Save(bookmark).Error
}

func (r *BookmarkDBRepository) DeleteBookmarkByID(id int) (bool, error) {
	result := r.db.Where("id = ?", id).Delete(&models.Bookmark{})
	if result.Error != nil {
		return false, result.Error
	}
	return result.RowsAffected == 1, nil
}

func (r *BookmarkDBRepository) GetBookmarksByUserID(userID int) (bookmarks []*models.Bookmark, _ error) {
	result := r.db.Where("user_id = ?", userID).Find(&bookmarks)
	if result.Error != nil {
		return nil, result.Error
	}

	return bookmarks, nil
}

func (r *BookmarkDBRepository) GetBookmarkByID(id int) (bookmark *models.Bookmark, _ error) {
	result := r.db.Where("id = ?", id).Limit(1).Find(&bookmark)
	return databases.HandleSingleDBResult(bookmark, result)
}
