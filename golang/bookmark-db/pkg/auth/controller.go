package auth

import (
	"log"
	"net/http"

	"github.com/adduc/exercises/golang/bookmark-db/pkg/auth/models"
	"github.com/adduc/exercises/golang/bookmark-db/pkg/sessions"
	sessionModels "github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"github.com/gin-gonic/gin"
)

type AuthController struct {
	UserRepository    UserRepository
	SessionRepository sessions.SessionRepository
}

func newAuthController(
	userRepo UserRepository,
	sessionRepo sessions.SessionRepository,
) *AuthController {
	return &AuthController{
		UserRepository:    userRepo,
		SessionRepository: sessionRepo,
	}
}

func (ac *AuthController) RegisterRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	ac.registerRoutes(router)
	ac.registerAuthzRoutes(authGroup)
}

func (ac *AuthController) registerRoutes(e *gin.Engine) {
	// Register routes for authentication
	e.GET("/register", ac.Register)
	e.POST("/register", ac.RegisterPost)
	e.GET("/login", ac.Login)
	e.POST("/login", ac.LoginPost)
}

func (ac *AuthController) registerAuthzRoutes(e *gin.RouterGroup) {
	e.GET("/logout", ac.Logout)
}

func (ac *AuthController) Register(c *gin.Context) {
	c.HTML(200, "register.html", gin.H{})
}

type RegisterForm struct {
	Username        string `form:"username" binding:"required,min=3,max=24"`
	Password        string `form:"password" binding:"required,min=8,max=128"`
	ConfirmPassword string `form:"confirm_password" binding:"required,eqfield=Password"`
}

func (ac *AuthController) RegisterPost(c *gin.Context) {
	var input RegisterForm
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "register.html", gin.H{"error": "Invalid input"})
		return
	}

	existingUser, err := ac.UserRepository.GetUserByUsername(input.Username)
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

	if err := ac.UserRepository.CreateUser(user); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create user"})
		return
	}

	session := sessionModels.NewSession(user)

	if err := ac.SessionRepository.CreateSession(session); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create session"})
		return
	}

	sessions.WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func (ac *AuthController) Login(c *gin.Context) {
	c.HTML(200, "login.html", gin.H{})
}

type LoginForm struct {
	Username string `form:"username" binding:"required,min=3,max=24"`
	Password string `form:"password" binding:"required,min=8,max=128"`
}

func (ac *AuthController) LoginPost(c *gin.Context) {
	var input LoginForm
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "login.html", gin.H{"error": "Invalid input"})
		return
	}

	user, err := ac.UserRepository.GetUserByUsername(input.Username)
	if err != nil {
		c.HTML(500, "login.html", gin.H{"error": "Failed to check for existing user"})
		return
	} else if user == nil || user.Username != input.Username {
		c.HTML(400, "login.html", gin.H{"error": "Invalid username or password"})
		return
	}

	session := sessionModels.NewSession(user)

	if err := ac.SessionRepository.CreateSession(session); err != nil {
		c.HTML(500, "login.html", gin.H{"error": "Failed to create session"})
		return
	}

	sessions.WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func (ac *AuthController) Logout(c *gin.Context) {
	session := c.MustGet("session").(*sessionModels.Session)

	if _, err := ac.SessionRepository.DeleteSessionByToken(session.Token); err != nil {
		log.Printf("Failed to delete session: %v\n", err)
		c.String(500, "An issue occurred while logging out; please try again")
		return
	}

	sessions.DeleteSessionCookie(c)

	c.Redirect(http.StatusFound, "/")
}
