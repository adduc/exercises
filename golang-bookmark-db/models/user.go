package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
)

type User struct {
	ID       uint   `gorm:"primarykey"`
	Username string `gorm:"unique"`
	Password string
}

func (u *User) SetPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	u.Password = string(hashedPassword)
	return nil
}

func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

type Session struct {
	ID        uint `gorm:"primarykey"`
	UserID    uint
	Token     string `gorm:"unique"`
	ExpiresAt time.Time
	CreatedAt time.Time
}
