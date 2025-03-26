package main

import (
	"crypto/rand"
	"embed"
	"encoding/base64"
	"fmt"
	"html/template"
	"net/http"
	"strconv"
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

	InitEnv()
	InitDB()
	InitRepos()

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

	g := e.Group("/", LoadSession, RequireSession)
	RegisterLandingAuthzRoutes(g)
	RegisterAuthAuthzRoutes(g)
	RegisterBookmarkAuthzRoutes(g)

	return e
}

// configuration

var Config struct {
	AppName           string `env:"APP_NAME" envDefault:"SingleFileApp"`
	ListenAddress     string `env:"LISTEN_ADDRESS" envDefault:":8080"`
	SessionCookieName string `env:"SESSION_COOKIE_NAME" envDefault:"session_token"`
}

func InitEnv() {
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

func InitDB() {
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
	return &DBs.Default, DBs.Default.AutoMigrate(
		&User{},
		&Session{},
		&Bookmark{},
	)
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

func NewSession(user *User) *Session {
	return &Session{
		UserID:    user.ID,
		Token:     generateSessionToken(),
		ExpiresAt: time.Now().Add(time.Hour * 24 * 30),
	}
}

func generateSessionToken() string {
	// generate 128-bit random token to use as session token
	// @see https://owasp.org/www-community/vulnerabilities/Insufficient_Session-ID_Length
	token := make([]byte, 16)
	rand.Read(token)
	return base64.StdEncoding.EncodeToString(token)
}

type Bookmark struct {
	ID     int    `gorm:"primaryKey"`
	UserID int    `gorm:"uniqueIndex:user_url"`
	Url    string `gorm:"uniqueIndex:user_url"`
	Note   string `gorm:"size:1024"`
}

// persistence

var Repos struct {
	Bookmark BookmarkRepository
	Session  SessionRepository
	User     UserRepository
}

func InitRepos() {
	Repos.Bookmark = &BookmarkDBRepository{db: DBs.Default}
	Repos.Session = &SessionDBRepository{db: DBs.Default}
	Repos.User = &UserDBRepository{db: DBs.Default}
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

type SessionRepository interface {
	CreateSession(session *Session) error
	DeleteSessionByToken(token string) (bool, error)
	GetSessionByToken(token string) (*Session, error)
}

type SessionDBRepository struct {
	db gorm.DB
}

func (r *SessionDBRepository) CreateSession(session *Session) error {
	return r.db.Create(session).Error
}

func (r *SessionDBRepository) DeleteSessionByToken(token string) (bool, error) {
	result := r.db.Where("token = ?", token).Delete(&Session{})

	if result.Error != nil {
		return false, result.Error
	}

	return result.RowsAffected == 1, nil
}

func (r *SessionDBRepository) GetSessionByToken(token string) (session *Session, _ error) {
	result := r.db.Where("token = ?", token).Limit(1).Find(&session)
	return handleSingleDBResult(session, result)
}

type UserRepository interface {
	CreateUser(user *User) error
	GetUserByID(id int) (*User, error)
	GetUserByUsername(username string) (*User, error)
}

type UserDBRepository struct {
	db gorm.DB
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

type BookmarkRepository interface {
	CreateBookmark(bookmark *Bookmark) error
	UpdateBookmark(bookmark *Bookmark) error
	DeleteBookmarkByID(id int) (bool, error)
	GetBookmarksByUserID(userID int) ([]*Bookmark, error)
	GetBookmarkByID(id int) (*Bookmark, error)
}

type BookmarkDBRepository struct {
	db gorm.DB
}

func (r *BookmarkDBRepository) CreateBookmark(bookmark *Bookmark) error {
	return r.db.Create(bookmark).Error
}

func (r *BookmarkDBRepository) UpdateBookmark(bookmark *Bookmark) error {
	return r.db.Save(bookmark).Error
}

func (r *BookmarkDBRepository) DeleteBookmarkByID(id int) (bool, error) {
	result := r.db.Where("id = ?", id).Delete(&Bookmark{})
	if result.Error != nil {
		return false, result.Error
	}
	return result.RowsAffected == 1, nil
}

func (r *BookmarkDBRepository) GetBookmarksByUserID(userID int) (bookmarks []*Bookmark, _ error) {
	result := r.db.Where("user_id = ?", userID).Find(&bookmarks)
	if result.Error != nil {
		return nil, result.Error
	}

	return bookmarks, nil
}

func (r *BookmarkDBRepository) GetBookmarkByID(id int) (bookmark *Bookmark, _ error) {
	result := r.db.Where("id = ?", id).Limit(1).Find(&bookmark)
	return handleSingleDBResult(bookmark, result)
}

// middleware

func LoadSession(c *gin.Context) {
	sessionToken, err := c.Cookie(Config.SessionCookieName)

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
		c.SetCookie(Config.SessionCookieName, "", -1, "/", "", false, true)
		c.Next()
		return
	}

	// @todo check if session is due for renewal

	c.Set("session", session)
}

func RequireSession(c *gin.Context) {
	session, exists := c.Get("session")
	if !exists || session == nil {
		c.SetCookie(Config.SessionCookieName, "", -1, "/", "", false, true)
		c.Redirect(http.StatusFound, "/login")
		c.Abort()
		return
	}
}

func WriteSessionCookie(c *gin.Context, session *Session) {
	expiresAt := int(time.Until(session.ExpiresAt).Seconds())
	c.SetCookie(Config.SessionCookieName, session.Token, expiresAt, "/", "", false, true)
}

func DeleteSessionCookie(c *gin.Context) {
	c.SetCookie(Config.SessionCookieName, "", -1, "/", "", false, true)
}

// landing routes

func RegisterLandingRoutes(e *gin.Engine) {
	e.GET("/", Landing)
}

func RegisterLandingAuthzRoutes(e *gin.RouterGroup) {
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
}

func RegisterAuthAuthzRoutes(e *gin.RouterGroup) {
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

	user := &User{Username: input.Username}

	if err := user.SetPassword(input.Password); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to set password"})
		return
	}

	if err := Repos.User.CreateUser(user); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create user"})
		return
	}

	session := NewSession(user)

	if err := Repos.Session.CreateSession(session); err != nil {
		c.HTML(500, "register.html", gin.H{"error": "Failed to create session"})
		return
	}

	WriteSessionCookie(c, session)
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

	session := NewSession(user)

	if err := Repos.Session.CreateSession(session); err != nil {
		c.HTML(500, "login.html", gin.H{"error": "Failed to create session"})
		return
	}

	WriteSessionCookie(c, session)
	c.Redirect(http.StatusFound, "/dashboard")
}

func Logout(c *gin.Context) {
	session, _ := c.Get("session")
	Repos.Session.DeleteSessionByToken(session.(*Session).Token)
	DeleteSessionCookie(c)

	c.Redirect(http.StatusFound, "/")
}

// bookmark routes

func RegisterBookmarkAuthzRoutes(e *gin.RouterGroup) {
	e.GET("/bookmarks", ListBookmarks)
	e.GET("/bookmarks/create", CreateBookmark)
	e.POST("/bookmarks/create", CreateBookmarkPost)
	e.GET("/bookmarks/:id/edit", EditBookmark)
	e.POST("/bookmarks/:id/edit", EditBookmarkPost)
	e.GET("/bookmarks/:id/delete", DeleteBookmark)
	e.POST("/bookmarks/:id/delete", DeleteBookmarkPost)
}

func ListBookmarks(c *gin.Context) {
	session, _ := c.Get("session")
	userID := session.(*Session).UserID

	var bookmarks []*Bookmark

	// @todo paginate bookmarks
	bookmarks, err := Repos.Bookmark.GetBookmarksByUserID(userID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmarks")
		return
	}

	c.HTML(200, "bookmarks.list.html", gin.H{
		"bookmarks": bookmarks,
	})
}

func CreateBookmark(c *gin.Context) {
	c.HTML(200, "bookmarks.create.html", gin.H{})
}

type CreateBookmarkInput struct {
	Url  string `form:"url" binding:"required,url"`
	Note string `form:"note" binding:"max=1024"`
}

func CreateBookmarkPost(c *gin.Context) {
	var input CreateBookmarkInput
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "bookmarks.create.html", gin.H{"error": "Invalid input"})
		return
	}

	session, _ := c.Get("session")

	bookmark := &Bookmark{
		UserID: session.(*Session).UserID,
		Url:    input.Url,
		Note:   input.Note,
	}

	if err := Repos.Bookmark.CreateBookmark(bookmark); err != nil {
		c.HTML(500, "bookmarks.create.html", gin.H{"error": "Failed to create bookmark"})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}

func EditBookmark(c *gin.Context) {
	id, ok := c.Params.Get("id")
	if !ok {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	bookmarkID, err := strconv.Atoi(id)
	if err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session, _ := c.Get("session")

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.(*Session).UserID {
		c.String(http.StatusNotFound, "Bookmark not found")
		return
	}

	c.HTML(200, "bookmarks.edit.html", gin.H{
		"bookmark": bookmark,
	})
}

type EditBookmarkInput struct {
	Url  string `form:"url" binding:"required,url"`
	Note string `form:"note" binding:"max=1024"`
}

func EditBookmarkPost(c *gin.Context) {
	id, ok := c.Params.Get("id")
	if !ok {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	bookmarkID, err := strconv.Atoi(id)
	if err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session, _ := c.Get("session")

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.(*Session).UserID {
		c.String(http.StatusNotFound, "Bookmark not found")
		return
	}

	var input EditBookmarkInput

	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "bookmarks.edit.html", gin.H{
			"error":    "Invalid input",
			"bookmark": bookmark,
		})
		return
	}

	bookmark.Url = input.Url
	bookmark.Note = input.Note

	if err := Repos.Bookmark.UpdateBookmark(bookmark); err != nil {
		c.HTML(500, "bookmarks.edit.html", gin.H{
			"error":    "Failed to update bookmark",
			"bookmark": bookmark,
		})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}

func DeleteBookmark(c *gin.Context) {
	id, ok := c.Params.Get("id")
	if !ok {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	bookmarkID, err := strconv.Atoi(id)
	if err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session, _ := c.Get("session")

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.(*Session).UserID {
		c.String(http.StatusNotFound, "Bookmark not found")
		return
	}

	c.HTML(200, "bookmarks.delete.html", gin.H{
		"bookmark": bookmark,
	})
}

func DeleteBookmarkPost(c *gin.Context) {
	id, ok := c.Params.Get("id")
	if !ok {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	bookmarkID, err := strconv.Atoi(id)
	if err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session, _ := c.Get("session")

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.(*Session).UserID {
		c.String(http.StatusNotFound, "Bookmark not found")
		return
	}

	if _, err := Repos.Bookmark.DeleteBookmarkByID(bookmarkID); err != nil {
		c.HTML(500, "bookmarks.delete.html", gin.H{
			"error":    "Failed to delete bookmark",
			"bookmark": bookmark,
		})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}
