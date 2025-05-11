#!/bin/sh

SCRIPT_PATH=$(realpath "$(/non/existent/command 2>&1 >/dev/null | sed 's/\(.*: \)\?\(.*\): line .*/\2/' || true)")
SCRIPT_DIR=$(dirname "$(realpath "$(/non/existent/command 2>&1 >/dev/null | sed 's/\(.*: \)\?\(.*\): line .*/\2/' || true)")")

echo "SCRIPT_PATH: ${SCRIPT_PATH}"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"
