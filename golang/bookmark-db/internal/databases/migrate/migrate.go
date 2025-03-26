package migrate

import (
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions"
	"gorm.io/gorm"
)

func Migrate() {
	dbErrorHandler(auth.Migrate())
	dbErrorHandler(bookmarks.Migrate())
	dbErrorHandler(sessions.Migrate())
}

func dbErrorHandler(db *gorm.DB, err error) *gorm.DB {
	if err != nil {
		panic(err)
	}
	return db
}
