package main

import (
	"log"

	"github.com/adduc/exercises/golang-rest-api/config"
	"github.com/adduc/exercises/golang-rest-api/db"
	server "github.com/adduc/exercises/golang-rest-api/http"
	"github.com/adduc/exercises/golang-rest-api/models"
)

func main() {
	if err := config.Init(); err != nil {
		log.Panicln("Could not load config", err)
	}
	if err := db.Init(); err != nil {
		log.Panicln("Could not connect to database", err)
	}
	if err := models.Init(); err != nil {
		log.Panicln("Could not initialize models", err)
	}

	server.Init()
}
