package sessions

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"gorm.io/gorm"
)

var sessionRepo SessionRepository

func NewSessionRepository() (SessionRepository, error) {
	db := databases.GetDefaultDB()
	sessionRepo = &SessionDBRepository{db: db}
	return sessionRepo, nil
}

func GetSessionRepository() (SessionRepository, error) {
	if sessionRepo == nil {
		return NewSessionRepository()
	}
	return sessionRepo, nil
}

type SessionRepository interface {
	CreateSession(session *models.Session) error
	DeleteSessionByToken(token string) (bool, error)
	GetSessionByToken(token string) (*models.Session, error)
}

type SessionDBRepository struct {
	db *gorm.DB
}

func (r *SessionDBRepository) CreateSession(session *models.Session) error {
	return r.db.Create(session).Error
}

func (r *SessionDBRepository) DeleteSessionByToken(token string) (bool, error) {
	result := r.db.Where("token = ?", token).Delete(&models.Session{})

	if result.Error != nil {
		return false, result.Error
	}

	return result.RowsAffected == 1, nil
}

func (r *SessionDBRepository) GetSessionByToken(token string) (session *models.Session, _ error) {
	result := r.db.Where("token = ?", token).Limit(1).Find(&session)
	return databases.HandleSingleDBResult(session, result)
}
