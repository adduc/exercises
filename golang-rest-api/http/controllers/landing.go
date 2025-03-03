package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type LandingController struct{}

func (h *LandingController) Landing(c *gin.Context) {
	c.HTML(http.StatusOK, "landing.html", nil)
}
