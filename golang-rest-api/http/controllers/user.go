package controllers

import (
	"log"
	"net/http"

	app_errors "github.com/adduc/exercises/golang-rest-api/errors"
	"github.com/adduc/exercises/golang-rest-api/http/forms"
	"github.com/adduc/exercises/golang-rest-api/models"
	"github.com/gin-gonic/gin"
)

var user = &models.User{}

type UserController struct{}

func (h *UserController) List(c *gin.Context) {
	users, err := user.List()
	if err != nil {
		log.Println("Error retrieving users", err)
		c.String(http.StatusInternalServerError, "Error retrieving users")
		return
	}

	c.JSON(http.StatusOK, users)
}

func (h *UserController) Create(c *gin.Context) {
	var userCreate forms.UserCreate

	if err := c.ShouldBind(&userCreate); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user.Email = userCreate.Email
	user.Password = userCreate.Password

	if err := user.Create(); err != nil {
		// check if err is DuplicateEmail
		if _, ok := err.(*app_errors.DuplicateEmail); ok {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email already exists"})
			return
		}
		log.Println("Error creating user", err)
		c.String(http.StatusInternalServerError, "Error creating user")
		return
	}

}
