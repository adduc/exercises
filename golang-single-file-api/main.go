package main

import (
	"embed"
	"fmt"
	"html/template"

	"github.com/caarlos0/env/v8"
	"github.com/gin-gonic/gin"
	_ "github.com/joho/godotenv/autoload"
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

type Session struct {
	ID     int    `gorm:"primaryKey"`
	UserID int    `gorm:"index"`
	Token  string `gorm:"unique"`
}

// persistence

var Repos struct {
	User UserRepository
}

func init() {
	Repos.User = &UserDBRepository{db: DBs.Default}
}

type UserRepository interface {
	GetUserByID(id int) (*User, error)
}

type UserDBRepository struct {
	db gorm.DB
}

func (r *UserDBRepository) GetUserByID(id int) (user *User, _ error) {
	result := r.db.Where("id = ?", id).Limit(1).Find(&user)
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

func RegisterPost(c *gin.Context) {

	user, err := Repos.User.GetUserByID(1)
	if err != nil {
		c.String(500, "Error retrieving user: %v", err)
		return
	}
	if user == nil {
		c.String(404, "User not found")
		return
	}
	c.String(200, "User found: %v", user.Username)

	// Handle registration
	// user := User{
	// 	Username: c.PostForm("username"),
	// 	Password: c.PostForm("password"),
	// }

	// db.Create(&user)
}

func Login(c *gin.Context) {
	c.HTML(200, "login.html", gin.H{})
}

func LoginPost(c *gin.Context) {
	// Handle login
}

func Logout(c *gin.Context) {
	// Handle logout
}
