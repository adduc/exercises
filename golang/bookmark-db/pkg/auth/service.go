package auth

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) error {
	userRepo, err := GetUserRepository()
	if err != nil {
		return err
	}

	sessionRepo, err := sessions.GetSessionRepository()
	if err != nil {
		return err
	}

	authController := newAuthController(userRepo, sessionRepo)
	authController.RegisterRoutes(router, authGroup)

	return nil
}

func Migrate() (*gorm.DB, error) {
	return databases.GetDefaultDB(), databases.GetDefaultDB().AutoMigrate(
		&models.User{},
	)
}
