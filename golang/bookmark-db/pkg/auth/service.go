package auth

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) {
	initRepos()
	initRoutes(router, authGroup)
}

func Migrate() (*gorm.DB, error) {
	return databases.GetDefaultDB(), databases.GetDefaultDB().AutoMigrate(
		&models.User{},
	)
}
