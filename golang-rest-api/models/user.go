package models

import (
	"time"

	"github.com/adduc/exercises/golang-rest-api/db"
)

type User struct {
	ID        uint `gorm:"primarykey"`
	Email     string
	Password  string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (u *User) List() ([]User, error) {
	var users []User
	result := db.GetDB().Find(&users)
	return users, result.Error
}
