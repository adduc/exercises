package models

import "github.com/adduc/exercises/golang-bookmark-db/data"

func Init() error {
	return data.GetDB().AutoMigrate(
		&Url{},
		&User{},
		&Session{},
		&Bookmark{},
	)
}
