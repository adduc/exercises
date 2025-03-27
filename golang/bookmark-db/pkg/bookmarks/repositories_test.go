package bookmarks

import (
	"testing"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB() *gorm.DB {
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	db.AutoMigrate(&models.Bookmark{})
	return db
}

func TestBookmarkDBRepository(t *testing.T) {
	repo := NewBookmarkDBRepository(setupTestDB())
	testBookmarkRepository(t, repo)
}

func TestInMemoryBookmarkRepository(t *testing.T) {
	repo := NewInMemoryBookmarkRepository()
	testBookmarkRepository(t, repo)
}

func testBookmarkRepository(t *testing.T, repo BookmarkRepository) {
	bookmark := &models.Bookmark{UserID: 1, URL: "http://example.com"}
	err := repo.CreateBookmark(bookmark)
	assert.NoError(t, err)
	assert.NotZero(t, bookmark.ID)

	bookmark.URL = "http://example.org"
	err = repo.UpdateBookmark(bookmark)
	assert.NoError(t, err)

	fetchedBookmark, err := repo.GetBookmarkByID(bookmark.ID)
	assert.NoError(t, err)
	assert.Equal(t, "http://example.org", fetchedBookmark.URL)

	bookmarks, err := repo.GetBookmarksByUserID(1)
	assert.NoError(t, err)
	assert.Len(t, bookmarks, 1)

	deleted, err := repo.DeleteBookmarkByID(bookmark.ID)
	assert.NoError(t, err)
	assert.True(t, deleted)

	fetchedBookmark, err = repo.GetBookmarkByID(bookmark.ID)
	assert.NoError(t, err)
	assert.Nil(t, fetchedBookmark)
}

func TestNewBookmarkRepository(t *testing.T) {
	// Backup original config
	originalConfig := config.Config

	// Test for sqlite
	config.Config.DBType = "sqlite"
	databases.DBs.Default = setupTestDB()
	repo, err := NewBookmarkRepository()
	assert.NoError(t, err)
	assert.NotNil(t, repo)
	assert.IsType(t, &BookmarkDBRepository{}, repo)

	// Test for memory
	config.Config.DBType = "memory"
	repo, err = NewBookmarkRepository()
	assert.NoError(t, err)
	assert.NotNil(t, repo)
	assert.IsType(t, &InMemoryBookmarkRepository{}, repo)

	// Test for unsupported database type
	config.Config.DBType = "unsupported"
	repo, err = NewBookmarkRepository()
	assert.Error(t, err)
	assert.Nil(t, repo)

	// Restore original config
	config.Config = originalConfig
}
