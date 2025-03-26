package sessions

import (
	"net/http"
	"time"

	"github.com/adduc/exercises/golang/bookmark-db/internal/config"
	"github.com/gin-gonic/gin"
)

func LoadSession(c *gin.Context) {
	sessionToken, err := c.Cookie(config.Config.SessionCookieName)

	if err != nil {
		c.Next()
		return
	}

	session, err := Repos.Session.GetSessionByToken(sessionToken)

	if err != nil {
		c.AbortWithError(500, err)
		return
	}

	if session == nil {
		c.Next()
		return
	}

	if session.ExpiresAt.Before(time.Now()) {
		c.SetCookie(config.Config.SessionCookieName, "", -1, "/", "", false, true)
		c.Next()
		return
	}

	// @todo check if session is due for renewal

	c.Set("session", session)
}

func RequireSession(c *gin.Context) {
	session, exists := c.Get("session")
	if !exists || session == nil {
		c.SetCookie(config.Config.SessionCookieName, "", -1, "/", "", false, true)
		c.Redirect(http.StatusFound, "/login")
		c.Abort()
		return
	}
}
