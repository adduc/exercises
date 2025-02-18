/*

Goal: using gin, create simple application with support for logging in

*/

package main

import (
	"embed"
	"html/template"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username string `gorm:"unique"`
	Password string
}

type Session struct {
	gorm.Model
	SessionID string `gorm:"unique"`
	UserID    uint
	ExpiresAt time.Time
}

//go:embed templates/*
var f embed.FS

func authenticate(db *gorm.DB, c *gin.Context, user User) {
	// create session, set cookie

	// create random 64 character string, store in sessionID
	sessionID := generateRandomString(64)

	// create session
	session := Session{
		SessionID: sessionID,
		UserID:    user.ID,
		ExpiresAt: time.Now().Add(24 * time.Hour), // session expires in 24 hours
	}

	// save session to database
	db.Create(&session)

	// set cookie
	http.SetCookie(c.Writer, &http.Cookie{
		Name:    "session_id",
		Value:   sessionID,
		Expires: session.ExpiresAt,
	})
}

func generateRandomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	bytes := make([]byte, n)
	for i := range bytes {
		bytes[i] = letters[rand.Intn(len(letters))]
	}
	return string(bytes)
}

func main() {

	// Initialize database

	db, err := gorm.Open(sqlite.Open("users.sqlite"), &gorm.Config{})
	if err != nil {
		panic("Failed to connect to database")
	}

	// Migrate the schema
	db.AutoMigrate(&User{}, &Session{})

	// Initialize gin

	r := gin.Default()

	templ := template.Must(template.New("").ParseFS(f, "templates/*.tmpl"))
	r.SetHTMLTemplate(templ)

	r.GET("/", func(c *gin.Context) {
		c.HTML(200, "index.tmpl", gin.H{})
	})

	// Dummy route
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "pong"})
	})

	// Register route
	r.GET("/register", func(c *gin.Context) {
		c.HTML(200, "register.tmpl", gin.H{})
	})

	r.POST("/register", func(c *gin.Context) {
		// handle registration form submission
		username := c.PostForm("username")
		password := c.PostForm("password")
		password2 := c.PostForm("password2")

		// to make sure the password was not mistyped, we prompt for the
		// password twice and fail if they do not match
		if password != password2 {
			c.HTML(400, "register.tmpl", gin.H{"error": "passwords do not match"})
			return
		}

		// check if user exists
		var user User
		if dbc := db.Where("username = ?", username).Limit(1).Find(&user); dbc.Error != nil {
			log.Println(dbc.Error)
			c.JSON(500, gin.H{"message": "internal server error"})
			return
		}

		if user.ID != 0 {
			c.JSON(400, gin.H{"message": "user already exists"})
			return
		}

		// hash password
		hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			log.Println(err)
			c.JSON(500, gin.H{"message": "internal server error"})
			return
		}

		newUser := User{Username: username, Password: string(hash)}

		if dbc := db.Create(&newUser); dbc.Error != nil {
			log.Println(dbc.Error)
			c.JSON(500, gin.H{"message": "internal server error"})
			return
		}

		authenticate(db, c, newUser)

		c.JSON(200, gin.H{"message": "registration successful", "user": username})
	})

	r.Run()
}
