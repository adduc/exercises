package db

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var db *gorm.DB

func Init() (err error) {
	db, err = gorm.Open(sqlite.Open("db.sqlite"), &gorm.Config{})

	return err
}

func GetDB() *gorm.DB {
	return db
}
