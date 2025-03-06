package models

import "time"

type Url struct {
	ID          uint    `gorm:"primarykey"`
	Url         string  `gorm:"unique"`
	Title       *string `gorm:"default:null"`
	Description *string `gorm:"default:null"`
	CreatedAt   time.Time
}

type Bookmark struct {
	ID        uint `gorm:"primarykey"`
	UrlID     uint
	UserID    uint
	Note      *string `gorm:"default:null"`
	CreatedAt time.Time
	UpdatedAt time.Time

	Url  Url  `gorm:"foreignKey:UrlID"`
	User User `gorm:"foreignKey:UserID"`
}
