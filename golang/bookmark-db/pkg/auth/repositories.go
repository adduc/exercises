package auth

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"gorm.io/gorm"
)

func initRepos() {
	Repos.User = &UserDBRepository{db: databases.DBs.Default}
}

var Repos struct {
	User UserRepository
}

type UserRepository interface {
	CreateUser(user *models.User) error
	GetUserByID(id int) (*models.User, error)
	GetUserByUsername(username string) (*models.User, error)
}

type UserDBRepository struct {
	db *gorm.DB
}

func (r *UserDBRepository) CreateUser(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *UserDBRepository) GetUserByID(id int) (user *models.User, _ error) {
	result := r.db.Where("id = ?", id).Limit(1).Find(&user)
	return databases.HandleSingleDBResult(user, result)
}

func (r *UserDBRepository) GetUserByUsername(username string) (user *models.User, _ error) {
	result := r.db.Where("username = ?", username).Limit(1).Find(&user)
	return databases.HandleSingleDBResult(user, result)
}
