package databases

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var databases struct {
	Default *gorm.DB
}

// Opens a new connection to the default database
//
// This function should not typically be called directly except for
// specific cases like testing or migrations
func NewDefaultDB() (*gorm.DB, error) {
	// TODO: use config to determine database connection parameters
	// TODO: optimize SQLite connection
	return gorm.Open(sqlite.Open("db.sqlite?journal_mode=WAL"), &gorm.Config{})
}

// Returns the default database connection (or creates one if it doesn't
// exist)
func GetDefaultDB() *gorm.DB {
	if databases.Default == nil {
		databases.Default = dbErrorHandler(NewDefaultDB())
	}

	return databases.Default
}

// Sets the default database connection
//
// This function should not typically be called directly except for
// specific cases like testing
func SetDefaultDB(db *gorm.DB) {
	databases.Default = db
}

// Handles a single database result
//
// Returns the entity if it was found, nil if it wasn't, or an error if
// one occurred
func HandleSingleDBResult[T any](entity *T, result *gorm.DB) (*T, error) {
	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return entity, nil
}

// Wrapper for gorm.DB.Error that panics if an error is encountered
func dbErrorHandler(db *gorm.DB, err error) *gorm.DB {
	if err != nil {
		panic(err)
	}
	return db
}
