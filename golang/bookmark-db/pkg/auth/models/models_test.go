package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSetPassword(t *testing.T) {
	user := &User{Username: "testuser"}
	err := user.SetPassword("securepassword")
	assert.NoError(t, err)
	assert.NotEmpty(t, user.Password)
}

func TestCheckPassword(t *testing.T) {
	user := &User{Username: "testuser"}
	err := user.SetPassword("securepassword")
	assert.NoError(t, err)

	assert.True(t, user.CheckPassword("securepassword"))
	assert.False(t, user.CheckPassword("wrongpassword"))
}
