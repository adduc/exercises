package auth

import (
	"errors"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"gorm.io/gorm"
)

var userRepository UserRepository

func NewUserRepository() (UserRepository, error) {
	switch config.Config.DBType {
	case "sqlite":
		db := databases.GetDefaultDB()
		userRepository = newUserDBRepository(db)
	default:
		return nil, errors.New("unsupported database type")
	}
	return userRepository, nil
}

func GetUserRepository() (UserRepository, error) {
	if userRepository == nil {
		return NewUserRepository()
	}
	return userRepository, nil
}

type UserRepository interface {
	CreateUser(user *models.User) error
	GetUserByID(id int) (*models.User, error)
	GetUserByUsername(username string) (*models.User, error)
}

type UserDBRepository struct {
	db *gorm.DB
}

func newUserDBRepository(db *gorm.DB) *UserDBRepository {
	return &UserDBRepository{db: db}
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
