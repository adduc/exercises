package landing

import "github.com/gin-gonic/gin"

type LandingController struct{}

func newLandingController() *LandingController {
	return &LandingController{}
}

func (lc *LandingController) RegisterRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	lc.registerRoutes(router)
	lc.registerAuthRoutes(authGroup)
}

func (lc *LandingController) registerRoutes(e *gin.Engine) {
	e.GET("/", lc.landing)
}

func (lc *LandingController) registerAuthRoutes(e *gin.RouterGroup) {
	e.GET("/dashboard", lc.dashboard)
}

func (lc *LandingController) landing(c *gin.Context) {
	c.HTML(200, "landing.html", gin.H{})
}

func (lc *LandingController) dashboard(c *gin.Context) {
	c.HTML(200, "dashboard.html", gin.H{})
}
