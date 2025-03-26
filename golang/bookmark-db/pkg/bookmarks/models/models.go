package models

type Bookmark struct {
	ID     int    `gorm:"primaryKey"`
	UserID int    `gorm:"uniqueIndex:user_url"`
	Url    string `gorm:"uniqueIndex:user_url"`
	Note   string `gorm:"size:1024"`
}
