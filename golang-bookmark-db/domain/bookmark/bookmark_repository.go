package bookmark

import "context"

type Repository interface {
	FindByUserID(ctx context.Context, userID uint) ([]*Bookmark, error)
}
