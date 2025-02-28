package models

import (
	"time"
)

type User struct {
	ID        uint   `gorm:"primarykey"`
	Email     string `gorm:"unique"`
	Password  string
	CreatedAt time.Time
	UpdatedAt time.Time
}
