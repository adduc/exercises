package http

import (
	"html/template"

	"github.com/adduc/exercises/golang-bookmark-db/http/controllers"
	"github.com/adduc/exercises/golang-bookmark-db/http/resources"
	"github.com/gin-gonic/gin"
)

func NewRouter() *gin.Engine {
	router := gin.Default()

	templ := template.Must(template.New("").ParseFS(resources.F, "templates/*.html"))
	router.SetHTMLTemplate(templ)

	landing := &controllers.LandingController{}
	router.GET("/", landing.Landing)

	auth := &controllers.AuthController{}
	router.GET("/register", auth.Register)
	router.POST("/register", auth.RegisterPost)
	router.GET("/login", auth.Login)
	router.POST("/login", auth.LoginPost)
	router.GET("/logout", auth.Logout)

	return router
}
