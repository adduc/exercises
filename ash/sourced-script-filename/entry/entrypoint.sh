#!/bin/sh

set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(realpath $(\' 2>&1 >/dev/null | sed 's/\(.*: \)\?\(.*\): line .*/\2/' || true))
SCRIPT_DIR=$(dirname $(realpath $(\' 2>&1 >/dev/null | sed 's/\(.*: \)\?\(.*\): line .*/\2/' || true)))

echo "SCRIPT_PATH: ${SCRIPT_PATH}"
echo "SCRIPT_DIR: ${SCRIPT_DIR}"

echo "sourcing source.sh"
source "${SCRIPT_DIR}/../source/source.sh"
