package main

import (
	"html/template"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/internal/databases/migrate"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/landing"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions"
	"github.com/adduc/exercises/golang/bookmark-db/resources"
	"github.com/gin-gonic/gin"
)

func main() {
	config.InitConfig()
	migrate.Migrate()

	router, authGroup := newRouter()

	auth.Init(router, authGroup)
	bookmarks.Init(router, authGroup)
	landing.Init(router, authGroup)
	sessions.Init(router, authGroup)

	router.Run(config.Config.ListenAddress)
}

func newRouter() (*gin.Engine, *gin.RouterGroup) {
	router := gin.Default()

	templ := template.Must(template.New("").ParseFS(resources.F, "templates/*.html"))
	router.SetHTMLTemplate(templ)

	authGroup := router.Group("/", sessions.LoadSession, sessions.RequireSession)

	return router, authGroup
}
