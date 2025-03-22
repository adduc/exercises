package forms

type BookmarkCreate struct {
	Url  string  `form:"url" binding:"required,url"`
	Note *string `form:"note" binding:"max=1024"`
}
