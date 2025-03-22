package counter

type Counter struct {
	ID    string `gorm:"primaryKey"`
	Value int
}
