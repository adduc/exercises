package errors

type DuplicateEmail struct{}

func (e *DuplicateEmail) Error() string {
	return "duplicate email"
}
