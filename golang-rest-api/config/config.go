package config

import (
	"github.com/caarlos0/env/v11"
)

type config struct {
	// @todo Define configuration settings here

	ListenAddress string `env:"LISTEN_ADDRESS" envDefault:":8080"`
}

var cfg config

func Init() error {
	err := env.Parse(&cfg)
	return err
}

func GetConfig() config {
	return cfg
}
