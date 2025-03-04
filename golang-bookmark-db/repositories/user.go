package repositories

import (
	"crypto/rand"
	"encoding/base64"
	"time"

	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/errors"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

type UserRepository struct {
}

func (u *UserRepository) GetByUsername(username string) (*models.User, error) {
	var conn = data.GetDB()
	var user models.User

	// find user by id
	result := conn.Where("username = ?", username).Limit(1).Find(&user)

	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, &errors.UserNotFound{}
	}

	return &user, nil
}

func (u *UserRepository) Create(user *models.User) error {
	var conn = data.GetDB()

	var existingUser models.User

	// check if username already exists
	result := conn.Where("username = ?", user.Username).Limit(1).Find(&existingUser)
	if result.Error != nil {
		return result.Error
	}

	if existingUser.ID != 0 {
		return &errors.DuplicateUsername{}
	}

	result = conn.Create(user)
	return result.Error
}

type SessionRespository struct {
}

func (s *SessionRespository) Create(user *models.User) (*models.Session, error) {
	var conn = data.GetDB()

	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token := make([]byte, 16)
	if _, err := rand.Read(token); err != nil {
		return nil, err
	}

	session := &models.Session{
		UserID:    user.ID,
		Token:     base64.StdEncoding.EncodeToString(token),
		ExpiresAt: time.Now().Add(2 * time.Minute),
	}

	result := conn.Create(session)
	if result.Error != nil {
		return nil, result.Error
	}

	return session, nil
}
