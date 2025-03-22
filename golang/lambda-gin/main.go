package main

import (
	"github.com/akrylysov/algnhsa"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.Any("/*proxyPath", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message":     "Hello, World!",
			"request_uri": c.Request.RequestURI,
			"uri":         c.Request.URL.Path,
		})
	})
	algnhsa.ListenAndServe(r, nil)
}
