package repositories

import (
	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/errors"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

type UserRepository struct {
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

func (u *UserRepository) GetByUsername(username string) (*models.User, error) {
	var conn = data.GetDB()
	var user models.User

	// find user by id
	result := conn.Where("username = ?", username).Limit(1).Find(&user)

	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return &user, nil
}

func (u *UserRepository) GetBySessionToken(token string) (*models.User, error) {
	var conn = data.GetDB()
	var user models.User

	result := conn.
		Preload("Sessions").
		Where("sessions.token = ?", token).
		Joins("JOIN sessions ON users.id = sessions.user_id").
		Limit(1).
		Find(&user)

	// if there is an error, bubble it up
	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return &user, nil
}
