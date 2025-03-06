package main

import (
	"fmt"

	"github.com/adduc/exercises/golang-counter-repository/domain/counter"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func main() {
	testMemoryRepo()
	testPersistentDBRepo()
	testmemoryDBRepo()
}

func testMemoryRepo() {
	repo := counter.NewMemoryRepository()
	testRepo(repo)
}

func testPersistentDBRepo() {
	db, err := gorm.Open(sqlite.Open("db.sqlite"), &gorm.Config{})
	db.AutoMigrate(&counter.Counter{})

	if err != nil {
		panic("failed to connect database")
	}

	repo := counter.NewDatabaseRepository(db)
	testRepo(repo)
}

func testmemoryDBRepo() {
	db, err := gorm.Open(sqlite.Open("file:memdb1?mode=memory&cache=shared"), &gorm.Config{})
	db.AutoMigrate(&counter.Counter{})

	if err != nil {
		panic("failed to connect database")
	}

	repo := counter.NewDatabaseRepository(db)
	testRepo(repo)
}

func testRepo(repo counter.Repository) {

	// fetching a nonexistent counter should return nil
	obj, _ := repo.Get("asdf")
	fmt.Println(obj)

	if obj == nil {
		obj = &counter.Counter{
			ID:    "asdf",
			Value: 0,
		}
		err := repo.Create(obj)
		if err != nil {
			fmt.Println(err)
		}
	}

	// fetching an existing counter should return the counter
	fetchedCounter1, _ := repo.Get(obj.ID)
	fmt.Println(
		"create",
		"counter", obj.ID, obj.Value,
		"fetchedCounter1", fetchedCounter1.Value,
	)

	// updating the counter should update the counter
	obj.Value++
	repo.Update(obj)
	fetchedCounter2, _ := repo.Get(obj.ID)
	fmt.Println(
		"update",
		"counter", obj.ID, obj.Value,
		"fetchedCounter1", fetchedCounter1.Value,
		"fetchedCounter2", fetchedCounter2.Value,
	)

	// deleting the counter should remove the counter
	repo.Delete(obj.ID)
	fmt.Println(
		"delete",
		"counter", obj.ID, obj.Value,
		"fetchedCounter1", fetchedCounter1.Value,
		"fetchedCounter2", fetchedCounter2.Value,
	)

	// fetching a nonexistent counter should return nil
	fetchedCounter3, _ := repo.Get(obj.ID)
	fmt.Println(
		"fetch ",
		"counter", obj.ID, obj.Value,
		"fetchedCounter1", fetchedCounter1.Value,
		"fetchedCounter2", fetchedCounter2.Value,
		"fetchedCounter3", fetchedCounter3,
	)

	fmt.Println("Hello, World!")
}
