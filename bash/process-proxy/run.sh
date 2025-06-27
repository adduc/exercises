#!/bin/bash

# Script-based process proxy (requires 'script' command)
# Usage: ./script_proxy.sh <command> [args...]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <command> [args...]" >&2
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_FILE="${SCRIPT_DIR}/proxy_$(date +%Y%m%d_%H%M%S).log"
TIMING_FILE="${SCRIPT_DIR}/timing_$(date +%Y%m%d_%H%M%S).log"

# Use script to capture all I/O
script -q -c "$*" -E "never" -f -B "$LOG_FILE" -T "$TIMING_FILE"
