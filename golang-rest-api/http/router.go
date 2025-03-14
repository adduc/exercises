package http

import (
	"html/template"

	"github.com/adduc/exercises/golang-rest-api/http/controllers"
	"github.com/adduc/exercises/golang-rest-api/http/resources"
	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {
	router := gin.Default()

	templ := template.Must(template.New("").ParseFS(resources.F, "templates/*.html"))
	router.SetHTMLTemplate(templ)

	landing := &controllers.LandingController{}
	router.GET("/", landing.Landing)

	health := &controllers.HealthController{}
	router.GET("/health", health.HealthCheck)

	user := &controllers.UserController{}
	router.GET("/users", user.List)
	router.POST("/users", user.Create)

	return router
}
