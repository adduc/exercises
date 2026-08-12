#!/usr/bin/env bash
#
# Native messaging host PoC. Chrome/Firefox launch this process and talk to it
# over stdin/stdout using the native messaging framing: each message is a
# 4-byte little-endian length prefix followed by that many bytes of UTF-8 JSON.
#
# stdout is reserved entirely for that protocol, so all diagnostics go to
# LOG_FILE instead of stderr/stdout.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/com.adduc.example.log"

log() {
  printf '%(%Y-%m-%dT%H:%M:%S)T %s\n' -1 "$1" >>"$LOG_FILE"
}

# Writes $1 (a non-negative integer, up to 2^32-1) to stdout as 4 raw
# little-endian bytes.
pack_le32() {
  local hex
  hex=$(printf '%08x' "$1")
  # Reverse the byte order for little-endian, then let %b interpret the
  # \xHH escapes straight to stdout -- that's the only point the 0x00 bytes
  # actually exist, so they never have to survive as a bash variable (bash
  # strings truncate at the first NUL).
  printf '%b' "\\x${hex:6:2}\\x${hex:4:2}\\x${hex:2:2}\\x${hex:0:2}"
}

# Reads exactly 4 raw little-endian bytes from stdin and prints the integer
# they encode. Returns non-zero if stdin didn't have 4 bytes to give.
unpack_le32() {
  local len
  len=$(dd bs=1 count=4 2>/dev/null | od -An -tu4 --endian=little | tr -d ' ')
  [ -z "$len" ] && return 1
  printf '%s' "$len"
}

# Reads one native-messaging frame from stdin and prints the JSON body to
# stdout. Returns non-zero once stdin is exhausted (browser closed the pipe).
read_message() {
  local len body
  len=$(unpack_le32) || return 1
  [ "$len" -eq 0 ] && { printf ''; return 0; }

  body=$(dd bs=1 count="$len" 2>/dev/null)
  printf '%s' "$body"
}

# Writes one native-messaging frame to stdout for the JSON given as $1.
write_message() {
  local body=$1 len
  len=$(printf '%s' "$body" | wc -c)
  pack_le32 "$len"
  printf '%s' "$body"
}

log "host started (pid $$)"

while message=$(read_message); do
  [ -z "$message" ] && break
  log "received: $message"

  text=$(printf '%s' "$message" | jq -r '.text // empty' 2>>"$LOG_FILE")
  reply=$(jq -nc --arg text "$text" --arg ts "$(date -u +%FT%TZ)" --arg pid "$$" \
    '{echo: $text, receivedAt: $ts, hostPid: ($pid | tonumber)}')

  log "replying: $reply"
  write_message "$reply"
done

log "host exiting (stdin closed)"
