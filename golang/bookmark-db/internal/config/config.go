package config

import (
	"github.com/caarlos0/env/v8"
	_ "github.com/joho/godotenv/autoload"
)

var Config struct {
	AppName           string `env:"APP_NAME" envDefault:"SingleFileApp"`
	ListenAddress     string `env:"LISTEN_ADDRESS" envDefault:":8080"`
	SessionCookieName string `env:"SESSION_COOKIE_NAME" envDefault:"session_token"`
	DBType            string `env:"DB_TYPE" envDefault:"sqlite"`
}

func InitConfig() {
	if err := env.Parse(&Config); err != nil {
		panic(err)
	}
}
