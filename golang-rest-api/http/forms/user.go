package forms

import "github.com/adduc/exercises/golang-rest-api/models"

type UserCreate struct {
	Email     string `form:"email" binding:"required,email"`
	Password  string `form:"password" binding:"required,min=6"`
	Password2 string `form:"password2" binding:"required,eqfield=Password"`
}

func (f *UserCreate) ToModel() models.User {
	return models.User{
		Email:    f.Email,
		Password: f.Password,
	}
}
