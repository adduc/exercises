package counter

type Repository interface {
	Create(counter *Counter) error
	Get(id string) (*Counter, error)
	Update(counter *Counter) error
	Delete(id string) error
}
