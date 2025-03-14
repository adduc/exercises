package config

import (
	"os"

	"github.com/caarlos0/env/v11"
	"github.com/joho/godotenv"
)

type config struct {
	// @todo Define configuration settings here

	ListenAddress string `env:"LISTEN_ADDRESS" envDefault:":8080"`
}

var cfg config

func Init() error {
	// load .env file (if exists)
	err := godotenv.Load()

	// ignore error if .env file is not found
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	// parse environment variables into config struct
	err = env.Parse(&cfg)

	return err
}

func GetConfig() config {
	return cfg
}
