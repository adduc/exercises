package models

import "github.com/adduc/exercises/golang-rest-api/data"

func Init() error {
	return data.GetDB().AutoMigrate(&User{})
}
