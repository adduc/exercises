package landing

import (
	"github.com/gin-gonic/gin"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) {
	initRoutes(router, authGroup)
}
