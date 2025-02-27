package server

import (
	"github.com/adduc/exercises/golang-rest-api/controllers"
	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {
	router := gin.Default()

	health := &controllers.HealthController{}
	router.GET("/health", health.HealthCheck)

	return router
}
