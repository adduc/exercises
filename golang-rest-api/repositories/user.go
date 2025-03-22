package repositories

import (
	"log"

	"github.com/adduc/exercises/golang-rest-api/data"
	"github.com/adduc/exercises/golang-rest-api/errors"
	"github.com/adduc/exercises/golang-rest-api/models"
)

type UserRepository struct {
}

func (u *UserRepository) List() ([]models.User, error) {
	var users []models.User
	result := data.GetDB().Find(&users)
	return users, result.Error
}

func (u *UserRepository) Create(user *models.User) error {
	var conn = data.GetDB()

	var existingUser models.User

	// check if email already exists
	if result := conn.Where("email = ?", user.Email).Limit(1).Find(&existingUser); result.Error != nil {
		log.Println("Error retrieving user", result.Error)
		return result.Error
	}

	if existingUser.ID != 0 {
		return &errors.DuplicateEmail{}
	}

	result := conn.Create(user)
	return result.Error
}
