package models

import "github.com/adduc/exercises/golang-rest-api/db"

func Init() error {
	return db.GetDB().AutoMigrate(&User{})
}
