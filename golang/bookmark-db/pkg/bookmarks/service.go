package bookmarks

import (
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) error {
	repo, err := NewBookmarkRepository()
	if err != nil {
		return err
	}

	c := newBookmarkController(repo)
	c.RegisterRoutes(router, authGroup)
	return nil
}

func Migrate() (*gorm.DB, error) {
	return databases.DBs.Default, databases.DBs.Default.AutoMigrate(
		&models.Bookmark{},
	)
}
