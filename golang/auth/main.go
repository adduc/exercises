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
	ID        uint   `gorm:"primarykey"`
	Username  string `gorm:"unique"`
	Password  string `json:"-"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

type Session struct {
	gorm.Model
	SessionID string `gorm:"unique"`
	UserID    uint
	ExpiresAt time.Time
}

//go:embed templates/*
var f embed.FS

// authenticate creates a session for the user and sets a cookie
func authenticate(db *gorm.DB, c *gin.Context, user User) {
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
	if err := db.AutoMigrate(&User{}, &Session{}); err != nil {
		log.Fatalf("Error migrating database: %v", err)
	}

	// Initialize gin
	r := gin.Default()

	templ := template.Must(template.New("").ParseFS(f, "templates/*.tmpl"))
	r.SetHTMLTemplate(templ)

	// Index route
	r.GET("/", func(c *gin.Context) {
		c.HTML(200, "index.tmpl", gin.H{})
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
			c.HTML(500, "register.tmpl", gin.H{"error": "internal server error"})
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
			c.HTML(500, "register.tmpl", gin.H{"error": "internal server error"})
			return
		}

		newUser := User{Username: username, Password: string(hash)}

		if dbc := db.Create(&newUser); dbc.Error != nil {
			log.Println(dbc.Error)
			c.HTML(500, "register.tmpl", gin.H{"error": "internal server error"})
			return
		}

		authenticate(db, c, newUser)

		c.Redirect(302, "/me")
	})

	r.GET("/login", func(c *gin.Context) {
		c.HTML(200, "login.tmpl", gin.H{})
	})

	r.POST("/login", func(c *gin.Context) {
		// handle login form submission
		username := c.PostForm("username")
		password := c.PostForm("password")

		// check if user exists
		var user User
		if dbc := db.Where("username = ?", username).Limit(1).Find(&user); dbc.Error != nil {
			log.Println(dbc.Error)
			c.HTML(500, "login.tmpl", gin.H{"error": "internal server error"})
			return
		}

		if user.ID == 0 {
			c.HTML(400, "login.tmpl", gin.H{"error": "username or password is incorrect"})
			return
		}

		// check password
		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
			c.HTML(400, "login.tmpl", gin.H{"error": "username or password is incorrect"})
			return
		}

		authenticate(db, c, user)

		c.Redirect(302, "/me")
	})

	authRoutes := r.Group("/", func(c *gin.Context) {
		// check if user is authenticated
		cookie, err := c.Cookie("session_id")
		if err != nil {
			c.HTML(401, "unauthorized.tmpl", gin.H{})
			c.Abort()
			return
		}
		var session Session
		if dbc := db.Where("session_id = ?", cookie).First(&session); dbc.Error != nil {
			log.Println(dbc.Error)
			c.JSON(500, gin.H{"message": "internal server error"})
			c.Abort()
			return
		}

		if session.ID == 0 {
			c.HTML(401, "unauthorized.tmpl", gin.H{})
			c.Abort()
			return
		}
		var user User
		if dbc := db.Where("id = ?", session.UserID).First(&user); dbc.Error != nil {
			log.Println(dbc.Error)
			c.JSON(500, gin.H{"message": "internal server error"})
			c.Abort()
			return
		}
		c.Set("user", user)
	})

	authRoutes.GET("/me", func(c *gin.Context) {
		user := c.MustGet("user").(User)
		c.JSON(200, gin.H{"user": user})
	})

	if err := r.Run(); err != nil {
		log.Fatal(err)
	}
}
