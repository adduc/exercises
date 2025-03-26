package sessions

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"gorm.io/gorm"
)

func initRepos() {
	Repos.Session = &SessionDBRepository{db: databases.DBs.Default}
}

func Migrate() (*gorm.DB, error) {
	return databases.DBs.Default, databases.DBs.Default.AutoMigrate(
		&models.Session{},
	)
}

var Repos struct {
	Session SessionRepository
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
