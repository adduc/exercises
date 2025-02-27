package server

import (
	"github.com/adduc/exercises/golang-rest-api/http/controllers"
	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {
	router := gin.Default()

	health := &controllers.HealthController{}
	router.GET("/health", health.HealthCheck)

	user := &controllers.UserController{}
	router.GET("/users", user.List)
	router.POST("/users", user.Create)

	return router
}
