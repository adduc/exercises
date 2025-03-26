package models

import (
	"crypto/rand"
	"encoding/base64"
	"time"

	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
)

type Session struct {
	ID        int       `gorm:"primaryKey"`
	UserID    int       `gorm:"index"`
	Token     string    `gorm:"unique"`
	ExpiresAt time.Time `gorm:"notNull"`
}

func NewSession(user *models.User) *Session {
	return &Session{
		UserID:    user.ID,
		Token:     generateSessionToken(),
		ExpiresAt: time.Now().Add(time.Hour * 24 * 30),
	}
}

func generateSessionToken() string {
	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token := make([]byte, 16)
	rand.Read(token)
	return base64.StdEncoding.EncodeToString(token)
}
