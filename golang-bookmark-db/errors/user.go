package errors

type DuplicateUsername struct{}

func (e *DuplicateUsername) Error() string {
	return "duplicate username"
}

type UserNotFound struct{}

func (e *UserNotFound) Error() string {
	return "user not found"
}
