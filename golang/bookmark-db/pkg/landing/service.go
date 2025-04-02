package landing

import (
	"github.com/gin-gonic/gin"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) error {
	c := newLandingController()
	c.RegisterRoutes(router, authGroup)
	return nil
}
