package auth

import (
	"log"
	"testing"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestUserDB() *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to the database: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	return db
}

func TestUserDBRepository(t *testing.T) {
	repo := newUserDBRepository(setupTestUserDB())
	testUserRepository(t, repo)
}

func testUserRepository(t *testing.T, repo UserRepository) {
	user := &models.User{Username: "testuser"}
	err := repo.CreateUser(user)
	assert.NoError(t, err)
	assert.NotZero(t, user.ID)

	fetchedUser, err := repo.GetUserByID(user.ID)
	assert.NoError(t, err)
	assert.Equal(t, "testuser", fetchedUser.Username)

	fetchedUserByUsername, err := repo.GetUserByUsername("testuser")
	assert.NoError(t, err)
	assert.Equal(t, user.ID, fetchedUserByUsername.ID)
}

func TestNewUserRepository(t *testing.T) {
	// Backup original config
	originalConfig := config.Config

	// Test for sqlite
	config.Config.DBType = "sqlite"
	databases.SetDefaultDB(setupTestUserDB())
	repo, err := NewUserRepository()
	assert.NoError(t, err)
	assert.NotNil(t, repo)
	assert.IsType(t, &UserDBRepository{}, repo)

	// Test for unsupported database type
	config.Config.DBType = "unsupported"
	repo, err = NewUserRepository()
	assert.Error(t, err)
	assert.Nil(t, repo)

	// Restore original config
	config.Config = originalConfig
}
