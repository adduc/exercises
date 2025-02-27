package db

import "gorm.io/gorm"

var db gorm.DB

func Init() error {
	// @todo Initialize database connection here
	return nil
}
func GetDB() gorm.DB {
	return db
}
