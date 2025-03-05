package http

import "github.com/adduc/exercises/golang-bookmark-db/config"

func Init() {
	config := config.GetConfig()
	r := NewRouter()
	r.Run(config.ListenAddress)
}
