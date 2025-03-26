package databases

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DBs struct {
	Default *gorm.DB
}

func InitDatabases() {
	DBs.Default = dbErrorHandler(NewPrimaryDB())
}

func dbErrorHandler(db *gorm.DB, err error) *gorm.DB {
	if err != nil {
		panic(err)
	}
	return db
}

func NewPrimaryDB() (*gorm.DB, error) {
	return gorm.Open(sqlite.Open("db.sqlite"), &gorm.Config{})
}

// return either the entity or an error
func HandleSingleDBResult[T any](entity *T, result *gorm.DB) (*T, error) {
	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return entity, nil
}
