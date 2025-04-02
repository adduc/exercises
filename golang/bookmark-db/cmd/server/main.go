package main

import (
	"html/template"
	"log"

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

	router, authGroup, err := newRouter()

	if err != nil {
		log.Fatalf("Failed to create router: %v", err)
	}

	if err := auth.Init(router, authGroup); err != nil {
		log.Fatalf("Failed to initialize auth: %v", err)
	}

	if err := bookmarks.Init(router, authGroup); err != nil {
		log.Fatalf("Failed to initialize bookmarks: %v", err)
	}

	if err := landing.Init(router, authGroup); err != nil {
		log.Fatalf("Failed to initialize landing: %v", err)
	}

	if err := router.Run(config.Config.ListenAddress); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func newRouter() (*gin.Engine, *gin.RouterGroup, error) {
	router := gin.Default()

	templ := template.Must(template.New("").ParseFS(resources.F, "templates/*.html"))
	router.SetHTMLTemplate(templ)

	sessionRepo, err := sessions.GetSessionRepository()
	if err != nil {
		return nil, nil, err
	}

	sm := sessions.NewSessionMiddleware(sessionRepo)
	authGroup := router.Group("/", sm.LoadSession, sm.RequireSession)

	return router, authGroup, nil
}
