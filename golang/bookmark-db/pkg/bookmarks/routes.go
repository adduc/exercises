package bookmarks

import (
	"net/http"
	"strconv"

	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	sessionModels "github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	registerAuthzRoutes(authGroup)
}

func registerAuthzRoutes(e *gin.RouterGroup) {
	e.GET("/bookmarks", ListBookmarks)
	e.GET("/bookmarks/create", CreateBookmark)
	e.POST("/bookmarks/create", CreateBookmarkPost)
	e.GET("/bookmarks/:id/edit", EditBookmark)
	e.POST("/bookmarks/:id/edit", EditBookmarkPost)
	e.GET("/bookmarks/:id/delete", DeleteBookmark)
	e.POST("/bookmarks/:id/delete", DeleteBookmarkPost)
}

func ListBookmarks(c *gin.Context) {
	session := c.MustGet("session").(*sessionModels.Session)
	userID := session.UserID

	var bookmarks []*models.Bookmark

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

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark := &models.Bookmark{
		UserID: session.UserID,
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

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.UserID {
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

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.UserID {
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

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.UserID {
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

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := Repos.Bookmark.GetBookmarkByID(bookmarkID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.UserID {
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
