package auth

import (
	"log"
	"net/http"

	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions"
	sessionModels "github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	registerRoutes(router)
	registerAuthzRoutes(authGroup)
}

func registerRoutes(e *gin.Engine) {
	// Register routes for authentication
	e.GET("/register", Register)
	e.POST("/register", RegisterPost)
	e.GET("/login", Login)
	e.POST("/login", LoginPost)
}

func registerAuthzRoutes(e *gin.RouterGroup) {
	e.GET("/logout", Logout)
}

func Register(c *gin.Context) {
	c.HTML(200, "register.html", gin.H{})
}

type RegisterForm struct {
	Username        string `form:"username" binding:"required,min=3,max=24"`
	Password        string `form:"password" binding:"required,min=8,max=128"`
	ConfirmPassword string `form:"confirm_password" binding:"required,eqfield=Password"`
}

func RegisterPost(c *gin.Context) {
	var input RegisterForm
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "register.html", gin.H{"error": "Invalid input"})
		return
	}

	existingUser, err := Repos.User.GetUserByUsername(input.Username)
	if err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to check for existing user"})
		return
	} else if existingUser != nil {
		c.HTML(400, "register.html", gin.H{"error": "Username already taken"})
		return
	}

	user := &models.User{Username: input.Username}

	if err := user.SetPassword(input.Password); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to set password"})
		return
	}

	if err := Repos.User.CreateUser(user); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create user"})
		return
	}

	session := sessionModels.NewSession(user)

	if err := sessions.Repos.Session.CreateSession(session); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create session"})
		return
	}

	sessions.WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func Login(c *gin.Context) {
	c.HTML(200, "login.html", gin.H{})
}

type LoginForm struct {
	Username string `form:"username" binding:"required,min=3,max=24"`
	Password string `form:"password" binding:"required,min=8,max=128"`
}

func LoginPost(c *gin.Context) {
	var input LoginForm
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "login.html", gin.H{"error": "Invalid input"})
		return
	}

	user, err := Repos.User.GetUserByUsername(input.Username)
	if err != nil {
		c.HTML(500, "login.html", gin.H{"error": "Failed to check for existing user"})
		return
	} else if user == nil || user.Username != input.Username {
		c.HTML(400, "login.html", gin.H{"error": "Invalid username or password"})
		return
	}

	session := sessionModels.NewSession(user)

	if err := sessions.Repos.Session.CreateSession(session); err != nil {
		c.HTML(500, "login.html", gin.H{"error": "Failed to create session"})
		return
	}

	sessions.WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func Logout(c *gin.Context) {
	session := c.MustGet("session").(*sessionModels.Session)

	if _, err := sessions.Repos.Session.DeleteSessionByToken(session.Token); err != nil {
		log.Printf("Failed to delete session: %v\n", err)
		c.String(500, "An issue occurred while logging out; please try again")
		return
	}

	sessions.DeleteSessionCookie(c)

	c.Redirect(http.StatusFound, "/")
}
