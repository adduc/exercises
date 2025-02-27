package main

import (
	"log"

	"github.com/adduc/exercises/golang-rest-api/config"
	"github.com/adduc/exercises/golang-rest-api/db"
	"github.com/adduc/exercises/golang-rest-api/models"
	"github.com/adduc/exercises/golang-rest-api/server"
)

func main() {
	if err := config.Init(); err != nil {
		log.Panicln("Could not load config", err)
	}
	if err := db.Init(); err != nil {
		log.Panicln("Could not connect to database", err)
	}

	// Migrate the schema
	db.GetDB().AutoMigrate(&models.User{})

	server.Init()
}
