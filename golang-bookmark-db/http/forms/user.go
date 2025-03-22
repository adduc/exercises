package forms

import "github.com/adduc/exercises/golang-bookmark-db/models"

type UserCreate struct {
	Username  string `form:"username" binding:"required,alphanum,min=3,max=20"`
	Password  string `form:"password" binding:"required,min=6,max=64"`
	Password2 string `form:"password2" binding:"required,eqfield=Password"`
}

func (f *UserCreate) ToModel() (u models.User, err error) {
	u.Username = f.Username
	if err = u.SetPassword(f.Password); err != nil {
		return models.User{}, err
	}
	return u, nil
}

type UserLogin struct {
	Username string `form:"username" binding:"required,alphanum,min=3,max=20"`
	Password string `form:"password" binding:"required,min=6,max=64"`
}

func (f *UserLogin) ToModel() (u models.User, err error) {
	u.Username = f.Username
	if err = u.SetPassword(f.Password); err != nil {
		return models.User{}, err
	}
	return u, nil
}
