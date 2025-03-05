package controllers

import (
	"log"
	"net/http"
	"time"

	"github.com/adduc/exercises/golang-bookmark-db/errors"
	"github.com/adduc/exercises/golang-bookmark-db/http/forms"
	"github.com/adduc/exercises/golang-bookmark-db/models"
	"github.com/adduc/exercises/golang-bookmark-db/repositories"
	"github.com/gin-gonic/gin"
)

type AuthController struct {
	ur *repositories.UserRepository
	sr *repositories.SessionRespository
}

func (a *AuthController) Register(c *gin.Context) {
	c.HTML(200, "register.html", gin.H{})
}

func (a *AuthController) RegisterPost(c *gin.Context) {
	var form forms.UserCreate

	if err := c.ShouldBind(&form); err != nil {
		c.HTML(http.StatusBadRequest, "register.html", gin.H{
			"error": "All fields are required",
		})
		return
	}

	user, err := form.ToModel()
	if err != nil {
		log.Println("Error converting form to model:", err)
		c.HTML(http.StatusInternalServerError, "register.html", gin.H{
			"error": "An error occurred while processing your request. Please try again.",
		})
		return
	}

	if err := a.ur.Create(&user); err != nil {
		// check if err is DuplicateUsername
		if _, ok := err.(*errors.DuplicateUsername); ok {
			c.HTML(http.StatusBadRequest, "register.html", gin.H{
				"error": "Username already exists",
			})
			return
		}
		log.Println("Error creating user:", err)
		c.HTML(http.StatusInternalServerError, "register.html", gin.H{
			"error": "An error occurred while creating your account. Please try again.",
		})
		return
	}

	// authenticate user
	if err := a.authenticate(c, user); err != nil {
		c.HTML(http.StatusInternalServerError, "register.html", gin.H{
			"error": "An error occurred while finalizing your registration. Please try again.",
		})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}

func (a *AuthController) Login(c *gin.Context) {
	c.HTML(200, "login.html", gin.H{})
}

func (a *AuthController) LoginPost(c *gin.Context) {
	var form forms.UserLogin

	if err := c.ShouldBind(&form); err != nil {
		c.HTML(http.StatusBadRequest, "login.html", gin.H{
			"error": "All fields are required",
		})
		return
	}

	user, err := a.ur.GetByUsername(form.Username)
	if err != nil {
		log.Println("Error getting user by username:", err)
		c.HTML(http.StatusInternalServerError, "login.html", gin.H{
			"error": "An error occurred while processing your request. Please try again.",
		})
		return
	}

	if user == nil {
		c.HTML(http.StatusBadRequest, "login.html", gin.H{
			"error": "Invalid username or password",
		})
		return
	}

	if !user.CheckPassword(form.Password) {
		c.HTML(http.StatusBadRequest, "login.html", gin.H{
			"error": "Invalid username or password",
		})
		return
	}

	// authenticate user
	if err := a.authenticate(c, *user); err != nil {
		c.HTML(http.StatusInternalServerError, "login.html", gin.H{
			"error": "An error occurred while finalizing your login. Please try again.",
		})
		return
	}

	// redirect to bookmark list
	c.Redirect(http.StatusFound, "/bookmarks")
}

func (a *AuthController) Logout(c *gin.Context) {
	c.SetCookie("session_token", "", -1, "/", "", false, true)
	c.Redirect(http.StatusFound, "/")
}

func (a *AuthController) authenticate(c *gin.Context, user models.User) error {
	// create session for user
	session, err := a.sr.Create(&user)
	if err != nil {
		log.Println("Error creating session:", err)
		return err
	}

	// set session cookie
	ttl := time.Until(session.ExpiresAt)
	c.SetCookie("session_token", session.Token, int(ttl.Seconds()), "/", "", false, true)
	return nil
}
