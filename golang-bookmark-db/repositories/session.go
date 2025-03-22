package repositories

import (
	"crypto/rand"
	"encoding/base64"
	"time"

	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

const sessionDuration = 2 * 24 * time.Hour

type SessionRespository struct {
}

func (s *SessionRespository) Create(user *models.User) (*models.Session, error) {
	var conn = data.GetDB()

	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token, err := generateSessionToken()
	if err != nil {
		return nil, err
	}

	session := &models.Session{
		UserID:    user.ID,
		Token:     token,
		ExpiresAt: time.Now().Add(sessionDuration),
	}

	result := conn.Create(session)
	if result.Error != nil {
		return nil, result.Error
	}

	return session, nil
}

func (s *SessionRespository) Refresh(session *models.Session) error {
	var conn = data.GetDB()

	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token, err := generateSessionToken()
	if err != nil {
		return err
	}

	session.Token = token
	session.ExpiresAt = time.Now().Add(sessionDuration)

	result := conn.Save(session)

	return result.Error
}

func generateSessionToken() (string, error) {
	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token := make([]byte, 16)
	if _, err := rand.Read(token); err != nil {
		return "", err
	}

	return base64.StdEncoding.EncodeToString(token), nil
}
