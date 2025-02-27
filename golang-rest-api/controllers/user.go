package controllers

import (
	"log"
	"net/http"

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
