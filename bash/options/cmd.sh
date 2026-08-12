#!/bin/sh

set -eu

usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help    Show this help message"
  echo "  -c, --config  Specify a configuration file"
}

config() {
  local arg_key="$1" config_file="$2"
  if [ -z "$config_file" ]; then
    2>&1 echo "Error: $arg_key requires a file argument"
    usage
    exit 1
  fi
  echo "Using config file: $config_file"
}

main() {
  local rotated=0 i=0 literal_count

  while [ $(($# - rotated)) -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -c=*|--config=*)
        config "${1%=*}" "${1#*=}"
        shift
        ;;
      -c|--config)
        config "$1" "${2:-}"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1"
        exit 1
        ;;
      *)
        set -- "$@" "$1"
        shift
        rotated=$((rotated + 1))
        ;;
    esac
  done

  # Positionals scanned before `--` were rotated to the tail of "$@", landing
  # after the literal remainder that followed `--`. Rotate the remainder
  # (everything but those `rotated` trailing items) to the back to restore
  # the original argument order.
  literal_count=$(($# - rotated))
  while [ "$i" -lt "$literal_count" ]; do
    set -- "$@" "$1"
    shift
    i=$((i + 1))
  done

  echo "Remaining arguments: $#"
  for arg; do
    echo "  - [$arg]"
  done
}

main "$@"
