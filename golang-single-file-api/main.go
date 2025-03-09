package main

import (
	"crypto/rand"
	"embed"
	"encoding/base64"
	"fmt"
	"html/template"
	"net/http"
	"time"

	"github.com/caarlos0/env/v8"
	"github.com/gin-gonic/gin"
	_ "github.com/joho/godotenv/autoload"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// ///
// sections
// ///
// main
// configuration
// resources
// connections
// models
// persistence
// landing routes
// auth routes
// middleware
// ///

// main

func main() {
	fmt.Println("Hi from " + Config.AppName)

	e := newRouter()

	e.Run(Config.ListenAddress)
}

func newRouter() *gin.Engine {
	e := gin.Default()

	// @todo move to middleware
	templ := template.Must(template.New("").ParseFS(F, "templates/*.html"))
	e.SetHTMLTemplate(templ)

	// global middleware

	// register routes
	RegisterLandingRoutes(e)
	RegisterAuthRoutes(e)

	return e
}

// configuration

var Config struct {
	AppName       string `env:"APP_NAME" envDefault:"SingleFileApp"`
	ListenAddress string `env:"LISTEN_ADDRESS" envDefault:":8080"`
}

func init() {
	if err := env.Parse(&Config); err != nil {
		panic(err)
	}
}

// resources

//go:embed templates/*
var F embed.FS

// connections

var DBs struct {
	Default gorm.DB
}

func init() {
	DBs.Default = dbErrorHandler(NewPrimaryDB())
	dbErrorHandler(MigratePrimaryDB())
}

func dbErrorHandler(db *gorm.DB, err error) gorm.DB {
	if err != nil {
		panic(err)
	}
	return *db
}

func NewPrimaryDB() (*gorm.DB, error) {
	return gorm.Open(sqlite.Open("db.sqlite"), &gorm.Config{})
}

func MigratePrimaryDB() (*gorm.DB, error) {
	return &DBs.Default, DBs.Default.AutoMigrate(&User{}, &Session{})
}

// models

type User struct {
	ID       int    `gorm:"primaryKey"`
	Username string `gorm:"unique"`
	Password string
}

func (u *User) SetPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	if err != nil {
		return err
	}

	u.Password = string(hashedPassword)
	return nil
}

func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

type Session struct {
	ID        int       `gorm:"primaryKey"`
	UserID    int       `gorm:"index"`
	Token     string    `gorm:"unique"`
	ExpiresAt time.Time `gorm:"notNull"`
}

// persistence

var Repos struct {
	User UserRepository
}

func init() {
	Repos.User = &UserDBRepository{db: DBs.Default}
}

type UserRepository interface {
	CreateSession(session *Session) error
	CreateUser(user *User) error
	GetUserByID(id int) (*User, error)
	GetUserByUsername(username string) (*User, error)
}

type UserDBRepository struct {
	db gorm.DB
}

func (r *UserDBRepository) CreateSession(session *Session) error {
	return r.db.Create(session).Error
}

func (r *UserDBRepository) CreateUser(user *User) error {
	return r.db.Create(user).Error
}

func (r *UserDBRepository) GetUserByID(id int) (user *User, _ error) {
	result := r.db.Where("id = ?", id).Limit(1).Find(&user)
	return handleSingleDBResult(user, result)
}

func (r *UserDBRepository) GetUserByUsername(username string) (user *User, _ error) {
	result := r.db.Where("username = ?", username).Limit(1).Find(&user)
	return handleSingleDBResult(user, result)
}

func handleSingleDBResult[T any](entity *T, result *gorm.DB) (*T, error) {
	if result.Error != nil {
		return nil, result.Error
	}

	if result.RowsAffected == 0 {
		return nil, nil
	}

	return entity, nil
}

// session

var SessionManager SessionManagerInterface

func init() {
	SessionManager = &SessionDBManager{db: DBs.Default}
}

type SessionManagerInterface interface {
	CreateSession(user *User) (*Session, error)
	// ValidateSession(token string) (*Session, error)
	// InvalidateSession(token string) error
}

type SessionDBManager struct {
	db gorm.DB
}

func (m *SessionDBManager) CreateSession(user *User) (*Session, error) {
	session := &Session{
		UserID:    user.ID,
		Token:     generateSessionToken(),
		ExpiresAt: time.Now().Add(time.Hour * 24 * 30),
	}

	if err := m.db.Create(session).Error; err != nil {
		return nil, err
	}

	return session, nil
}

func WriteSessionCookie(c *gin.Context, session *Session) {
	expiresAt := int(time.Until(session.ExpiresAt).Seconds())
	c.SetCookie("session_token", session.Token, expiresAt, "/", "", false, true)
}

func generateSessionToken() string {
	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token := make([]byte, 16)
	rand.Read(token)
	return base64.StdEncoding.EncodeToString(token)
}

// landing routes

func RegisterLandingRoutes(e *gin.Engine) {
	// Register routes for landing page
	e.GET("/", Landing)
	e.GET("/dashboard", Dashboard)
}

func Landing(c *gin.Context) {
	c.HTML(200, "landing.html", gin.H{})
}

func Dashboard(c *gin.Context) {
	c.HTML(200, "dashboard.html", gin.H{})
}

// auth routes

func RegisterAuthRoutes(e *gin.Engine) {
	// Register routes for authentication
	e.GET("/register", Register)
	e.POST("/register", RegisterPost)
	e.GET("/login", Login)
	e.POST("/login", LoginPost)
	e.GET("/logout", Logout)
}

func Register(c *gin.Context) {
	c.HTML(200, "register.html", gin.H{})
}

type RegisterFormInput struct {
	Username        string `form:"username" binding:"required,min=3,max=24"`
	Password        string `form:"password" binding:"required,min=8,max=128"`
	ConfirmPassword string `form:"confirm_password" binding:"required,eqfield=Password"`
}

func RegisterPost(c *gin.Context) {
	var input RegisterFormInput
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

	user := &User{Username: input.Username}

	if err := user.SetPassword(input.Password); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to set password"})
		return
	}

	if err := Repos.User.CreateUser(user); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create user"})
		return
	}

	session, err := SessionManager.CreateSession(user)
	if err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create session"})
		return
	}

	WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func Login(c *gin.Context) {
	c.HTML(200, "login.html", gin.H{})
}

type LoginFormInput struct {
	Username string `form:"username" binding:"required,min=3,max=24"`
	Password string `form:"password" binding:"required,min=8,max=128"`
}

func LoginPost(c *gin.Context) {
	var input LoginFormInput
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

	session, err := SessionManager.CreateSession(user)
	if err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create session"})
		return
	}

	WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func Logout(c *gin.Context) {
	// Handle logout
}
