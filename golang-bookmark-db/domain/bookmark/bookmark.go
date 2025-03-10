package bookmark

import "time"

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
