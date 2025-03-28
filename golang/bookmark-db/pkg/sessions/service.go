package sessions

import (
	"time"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"github.com/gin-gonic/gin"
)

func Init(router *gin.Engine, authGroup *gin.RouterGroup) error {
	initRepos()

	return nil
}

func WriteSessionCookie(c *gin.Context, session *models.Session) {
	expiresAt := int(time.Until(session.ExpiresAt).Seconds())
	c.SetCookie(config.Config.SessionCookieName, session.Token, expiresAt, "/", "", false, true)
}

func DeleteSessionCookie(c *gin.Context) {
	c.SetCookie(config.Config.SessionCookieName, "", -1, "/", "", false, true)
}
