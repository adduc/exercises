package main

import (
	"log"

	"github.com/adduc/exercises/golang-bookmark-db/config"
	"github.com/adduc/exercises/golang-bookmark-db/data"
	"github.com/adduc/exercises/golang-bookmark-db/http"
	"github.com/adduc/exercises/golang-bookmark-db/models"
)

func main() {
	if err := config.Init(); err != nil {
		log.Panicln("Could not load config", err)
	}
	if err := data.Init(); err != nil {
		log.Panicln("Could not connect to database", err)
	}
	if err := models.Init(); err != nil {
		log.Panicln("Could not initialize models", err)
	}

	http.Init()
}
