package bookmarks

import (
	"net/http"

	"github.com/adduc/exercises/golang/bookmark-db/pkg/bookmarks/models"
	sessionModels "github.com/adduc/exercises/golang/bookmark-db/pkg/sessions/models"
	"github.com/gin-gonic/gin"
)

type BookmarkController struct {
	BookmarkRepository BookmarkRepository
}

func newBookmarkController(repo BookmarkRepository) *BookmarkController {
	return &BookmarkController{
		BookmarkRepository: repo,
	}
}

func (bc *BookmarkController) RegisterRoutes(router *gin.Engine, authGroup *gin.RouterGroup) {
	bc.registerAuthRoutes(authGroup)
}

func (bc *BookmarkController) registerAuthRoutes(rg *gin.RouterGroup) {
	rg.GET("/bookmarks", bc.ListBookmarks)
	rg.GET("/bookmarks/create", bc.CreateBookmark)
	rg.POST("/bookmarks/create", bc.CreateBookmarkPost)
	rg.GET("/bookmarks/:id/edit", bc.EditBookmark)
	rg.POST("/bookmarks/:id/edit", bc.EditBookmarkPost)
	rg.GET("/bookmarks/:id/delete", bc.DeleteBookmark)
	rg.POST("/bookmarks/:id/delete", bc.DeleteBookmarkPost)
}

func (bc *BookmarkController) ListBookmarks(c *gin.Context) {
	session := c.MustGet("session").(*sessionModels.Session)
	userID := session.UserID

	var bookmarks []*models.Bookmark

	// @todo paginate bookmarks
	bookmarks, err := bc.BookmarkRepository.GetBookmarksByUserID(userID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmarks")
		return
	}

	c.HTML(200, "bookmarks.list.html", gin.H{
		"bookmarks": bookmarks,
	})
}

func (bc *BookmarkController) CreateBookmark(c *gin.Context) {
	c.HTML(200, "bookmarks.create.html", gin.H{})
}

type CreateBookmarkInput struct {
	URL  string `form:"url" binding:"required,url"`
	Note string `form:"note" binding:"max=1024"`
}

func (bc *BookmarkController) CreateBookmarkPost(c *gin.Context) {
	var input CreateBookmarkInput
	if err := c.ShouldBind(&input); err != nil {
		c.HTML(400, "bookmarks.create.html", gin.H{"error": "Invalid input"})
		return
	}

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark := &models.Bookmark{
		UserID: session.UserID,
		URL:    input.URL,
		Note:   input.Note,
	}

	if err := bc.BookmarkRepository.CreateBookmark(bookmark); err != nil {
		c.HTML(500, "bookmarks.create.html", gin.H{"error": "Failed to create bookmark"})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}

type BookmarkURI struct {
	ID int `uri:"id" binding:"required"`
}

func (bc *BookmarkController) EditBookmark(c *gin.Context) {
	var uri BookmarkURI
	if err := c.ShouldBindUri(&uri); err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := bc.BookmarkRepository.GetBookmarkByID(uri.ID)
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
	URL  string `form:"url" binding:"required,url"`
	Note string `form:"note" binding:"max=1024"`
}

func (bc *BookmarkController) EditBookmarkPost(c *gin.Context) {
	var uri BookmarkURI
	if err := c.ShouldBindUri(&uri); err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := bc.BookmarkRepository.GetBookmarkByID(uri.ID)
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

	bookmark.URL = input.URL
	bookmark.Note = input.Note

	if err := bc.BookmarkRepository.UpdateBookmark(bookmark); err != nil {
		c.HTML(500, "bookmarks.edit.html", gin.H{
			"error":    "Failed to update bookmark",
			"bookmark": bookmark,
		})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}

func (bc *BookmarkController) DeleteBookmark(c *gin.Context) {
	var uri BookmarkURI
	if err := c.ShouldBindUri(&uri); err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := bc.BookmarkRepository.GetBookmarkByID(uri.ID)
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

func (bc *BookmarkController) DeleteBookmarkPost(c *gin.Context) {
	var uri BookmarkURI
	if err := c.ShouldBindUri(&uri); err != nil {
		c.String(http.StatusBadRequest, "Invalid bookmark ID")
		return
	}

	session := c.MustGet("session").(*sessionModels.Session)

	bookmark, err := bc.BookmarkRepository.GetBookmarkByID(uri.ID)
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to fetch bookmark")
		return
	}

	if bookmark == nil || bookmark.UserID != session.UserID {
		c.String(http.StatusNotFound, "Bookmark not found")
		return
	}

	if _, err := bc.BookmarkRepository.DeleteBookmarkByID(uri.ID); err != nil {
		c.HTML(500, "bookmarks.delete.html", gin.H{
			"error":    "Failed to delete bookmark",
			"bookmark": bookmark,
		})
		return
	}

	c.Redirect(http.StatusFound, "/bookmarks")
}
