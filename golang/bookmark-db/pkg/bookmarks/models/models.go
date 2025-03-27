package models

type Bookmark struct {
	ID     int    `gorm:"primaryKey"`
	UserID int    `gorm:"uniqueIndex:user_url"`
	URL    string `gorm:"uniqueIndex:user_url"`
	Note   string `gorm:"size:1024"`
}
