package models

import (
	"log"
	"time"

	"github.com/adduc/exercises/golang-rest-api/db"
	"github.com/adduc/exercises/golang-rest-api/errors"
)

type User struct {
	ID        uint   `gorm:"primarykey"`
	Email     string `gorm:"unique"`
	Password  string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (u *User) List() ([]User, error) {
	var users []User
	result := db.GetDB().Find(&users)
	return users, result.Error
}

func (u *User) Create() error {
	var conn = db.GetDB()

	// check if email already exists
	var user User
	if result := conn.Where("email = ?", u.Email).Limit(1).Find(&user); result.Error != nil {
		log.Println("Error retrieving user", result.Error)
		return result.Error
	}

	if user.ID != 0 {
		return &errors.DuplicateEmail{}
	}

	result := conn.Create(u)
	return result.Error
}
