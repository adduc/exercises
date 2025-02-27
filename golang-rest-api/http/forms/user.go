package forms

type UserCreate struct {
	Email     string `form:"email" binding:"required,email"`
	Password  string `form:"password" binding:"required,min=6"`
	Password2 string `form:"password2" binding:"required,eqfield=Password"`
}
