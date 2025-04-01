package bookmarks

import (
	"errors"
	"sync"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	"gorm.io/gorm"
)

var bookmarkRepository BookmarkRepository

func NewBookmarkRepository() (BookmarkRepository, error) {
	switch config.Config.DBType {
	case "sqlite":
		db := databases.GetDefaultDB()
		bookmarkRepository = newBookmarkDBRepository(db)
	case "memory":
		bookmarkRepository = newInMemoryBookmarkRepository()
	default:
		return nil, errors.New("unsupported database type")
	}

	return bookmarkRepository, nil
}

func GetBookmarkRepository() (BookmarkRepository, error) {
	if bookmarkRepository == nil {
		return NewBookmarkRepository()
	}
	return bookmarkRepository, nil
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

func newBookmarkDBRepository(db *gorm.DB) *BookmarkDBRepository {
	return &BookmarkDBRepository{db: db}
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

// InMemoryBookmarkRepository is an in-memory implementation of BookmarkRepository
type InMemoryBookmarkRepository struct {
	mu        sync.Mutex
	bookmarks map[int]*models.Bookmark
	nextID    int
}

func newInMemoryBookmarkRepository() *InMemoryBookmarkRepository {
	return &InMemoryBookmarkRepository{
		bookmarks: make(map[int]*models.Bookmark),
		nextID:    1,
	}
}

func (r *InMemoryBookmarkRepository) CreateBookmark(bookmark *models.Bookmark) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	bookmark.ID = r.nextID
	r.bookmarks[r.nextID] = bookmark
	r.nextID++
	return nil
}

func (r *InMemoryBookmarkRepository) UpdateBookmark(bookmark *models.Bookmark) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.bookmarks[bookmark.ID]; !exists {
		return errors.New("bookmark not found")
	}
	r.bookmarks[bookmark.ID] = bookmark
	return nil
}

func (r *InMemoryBookmarkRepository) DeleteBookmarkByID(id int) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.bookmarks[id]; !exists {
		return false, errors.New("bookmark not found")
	}
	delete(r.bookmarks, id)
	return true, nil
}

func (r *InMemoryBookmarkRepository) GetBookmarksByUserID(userID int) ([]*models.Bookmark, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	var bookmarks []*models.Bookmark
	for _, bookmark := range r.bookmarks {
		if bookmark.UserID == userID {
			bookmarks = append(bookmarks, bookmark)
		}
	}
	return bookmarks, nil
}

func (r *InMemoryBookmarkRepository) GetBookmarkByID(id int) (*models.Bookmark, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	bookmark, exists := r.bookmarks[id]
	if !exists {
		return nil, nil
	}
	return bookmark, nil
}
