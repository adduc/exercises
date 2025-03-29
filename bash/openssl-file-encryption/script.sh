#!/bin/bash

preflight() {
  # Error out on command failure
  set -o errexit

  # Error out on pipefail
  set -o pipefail

  # Error out on undefined variables
  set -o nounset

  # Load in environment variable file (if it exists)
  # shellcheck disable=SC1091 # don't worry about checking .env file
  [ -f .env ] && { set -a; source .env; set +a; }

  # Ensure required environment variables are set
  require_env "SALT"
  require_env "PASS"

  if [ "$#" -lt 2 ]; then
	err "Not enough arguments"
    echo "Usage: ./script.sh [encrypt|decrypt] <...files>"
	echo ""
	echo "Encrypts or decrypts files using AES-256-CBC with PBKDF2 and a salt"
	echo "The SALT and PASS environment variables must be set (or provided in .env)"
	echo ""
	echo "Example: ./script.sh encrypt file1.txt file2.txt"
	echo "Example: ./script.sh decrypt file1.txt.enc file2.txt.enc"
    exit 1
  fi

  # Set the image to use
  IMAGE="alpine/openssl:3.3.2"

  # Set the command to use
  CMD="docker run --rm \
  	--env SALT --env PASS \
	-v .:/data -w /data \
	${IMAGE} \
	aes-256-cbc -pbkdf2 -iter 20000 -salt -md sha256 -a -S ${SALT} -pass env:PASS"
}

err() { echo "$@" 1>&2; }
errexit() { err "$@"; exit 1; }
require_env() { [ -n "$1" ] || errexit "Env var $1 is required, but not set"; }

encrypt() {
  for file in "$@"; do
	[ -f "$file" ] || errexit "File not found: $file"
	$CMD -e -in "$file" -out "${file}.enc"
  done
}

decrypt() {
  for file in "$@"; do
	[ -f "$file" ] || errexit "File not found: $file"
	$CMD -d -in "$file" -out "${file%.enc}"
  done
}

main() {
  preflight "$@"

  case "$1" in
    encrypt) encrypt "${@:2}" ;;
    decrypt) decrypt "${@:2}" ;;
    *) errexit "Invalid command: $1"
  esac
}

main "$@"