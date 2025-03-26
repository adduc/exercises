package landing

import "github.com/gin-gonic/gin"

func initRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	registerRoutes(router)
	registerAuthzRoutes(authGroup)
}

func registerRoutes(e *gin.Engine) {
	e.GET("/", landing)
}

func registerAuthzRoutes(e *gin.RouterGroup) {
	e.GET("/dashboard", dashboard)
}

func landing(c *gin.Context) {
	c.HTML(200, "landing.html", gin.H{})
}

func dashboard(c *gin.Context) {
	c.HTML(200, "dashboard.html", gin.H{})
}
