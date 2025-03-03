package http

import "github.com/adduc/exercises/golang-rest-api/config"

func Init() {
	config := config.GetConfig()
	r := NewRouter()
	r.Run(config.ListenAddress)
}
