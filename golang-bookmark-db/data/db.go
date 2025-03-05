package data

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var db *gorm.DB

func InitDB() (err error) {
	db, err = gorm.Open(sqlite.Open("db.sqlite"), &gorm.Config{})

	return err
}

func GetDB() *gorm.DB {
	if db == nil {
		panic("Database not initialized")
	}

	return db
}
