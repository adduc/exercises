package middlewares

import (
	"log"
	"net/http"
	"time"

	"github.com/adduc/exercises/golang-bookmark-db/repositories"
	"github.com/gin-gonic/gin"
)

type AuthMiddleware struct {
	ur *repositories.UserRepository
	sr *repositories.SessionRespository
}

func (a *AuthMiddleware) RequireAuth(c *gin.Context) {
	session_token, err := c.Cookie("session_token")
	if err != nil || session_token == "" {
		c.Redirect(http.StatusTemporaryRedirect, "/login")
		c.Abort()
		return
	}

	user, err := a.ur.GetBySessionToken(session_token)

	if err != nil {
		log.Println("Error getting user by session token:", err)
		c.HTML(http.StatusInternalServerError, "error.html", gin.H{
			"error": "An error occurred while processing your request. Please try again.",
		})
		c.Abort()
		return
	}

	if user == nil {
		c.Redirect(http.StatusTemporaryRedirect, "/login")
		c.Abort()
		return
	}

	// @todo consider refreshing session token if it's close to expiration
	if user.Sessions[0].ExpiresAt.Before(time.Now().Add(5 * time.Minute)) {
		a.sr.Refresh(&user.Sessions[0])
		ttl := time.Until(user.Sessions[0].ExpiresAt)
		c.SetCookie("session_token", user.Sessions[0].Token, int(ttl.Seconds()), "/", "", false, true)
	}

	c.Set("user", user)
	c.Next()
}
