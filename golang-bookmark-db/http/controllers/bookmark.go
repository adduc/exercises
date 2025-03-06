package controllers

import (
	"net/http"

	"github.com/adduc/exercises/golang-bookmark-db/http/forms"
	"github.com/adduc/exercises/golang-bookmark-db/models"
	"github.com/adduc/exercises/golang-bookmark-db/repositories"
	"github.com/gin-gonic/gin"
)

type BookmarkController struct {
	br *repositories.BookmarkRepository
}

func (b *BookmarkController) getUser(c *gin.Context) *models.User {
	user, exists := c.Get("user")

	if !exists {
		return nil
	}

	// check if user is authenticated
	if user == nil {
		return nil
	}

	// check if user is authenticated
	if _, ok := user.(*models.User); !ok {
		return nil
	}

	// check if user is authenticated
	if user.(*models.User).ID == 0 {
		return nil
	}

	return user.(*models.User)
}

func (b *BookmarkController) Index(c *gin.Context) {
	user := b.getUser(c)

	if user == nil {
		c.Redirect(302, "/login")
		return
	}

	// get user bookmarks
	bookmarks, err := b.br.FindByUserID(user.ID)

	if err != nil {
		c.HTML(500, "error.html", gin.H{
			"error": "An error occurred while retrieving your bookmarks. Please try again.",
		})
		return
	}

	c.HTML(200, "bookmarks.index.html", gin.H{
		"Bookmarks": bookmarks,
		"User":      user,
	})
}

func (b *BookmarkController) Create(c *gin.Context) {
	c.HTML(200, "bookmarks.create.html", gin.H{})
}

func (b *BookmarkController) CreatePost(c *gin.Context) {
	user := b.getUser(c)

	if user == nil {
		c.Redirect(302, "/login")
		return
	}

	var form forms.BookmarkCreate

	if err := c.ShouldBind(&form); err != nil {
		c.HTML(http.StatusBadRequest, "bookmarks.create.html", gin.H{
			"error": "All fields are required",
		})
		return
	}

	bookmark := &models.Bookmark{
		Note: form.Note,
	}

	if err := b.br.Create(bookmark, *user, form.Url); err != nil {
		c.HTML(500, "bookmarks.create.html", gin.H{
			"error": "An error occurred while creating your bookmark. Please try again.",
		})
		return
	}

	c.Redirect(302, "/bookmarks")
}
