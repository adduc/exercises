#!/bin/bash
#
# Goal: Enhance the shell prompt to display current vcs ref, split
# directory between repo root and subdir within repo


set -o errexit -o pipefail -o nounset

# bash will emit a DEBUG signal prior to executing any command. We can
# use this to record the start time of the command.
trap 'TIMER=${TIMER:-$EPOCHREALTIME}' DEBUG

__prompt_command() {
  # grab exit code of last command
  EXIT_CODE=$?

  local TIMER_SECS COL_RESET COL_DARK_GRAY COL_GREEN COL_CYAN \
    TEXT_USER TEXT_HOST TEXT_PATH TEXT_TIME LINES RIGHT_TEXT HR_LENGTH \
    PS1_HR DIR VCS_TYPE VCS_PATH VCS_REF DIR

  # determine duration of last command
  TIMER_SECS=$(echo "($EPOCHREALTIME - $TIMER)" | bc)

  # limit decimal places to 3 and add comma to thousands
  TIMER_SECS=$(printf "%'.3f" "$TIMER_SECS")

  TEXT_TIME="$(date +%H:%M:%S)"

  # Build prompt text for the last command's execution
  RIGHT_TEXT="$TEXT_TIME (exit: $EXIT_CODE) (duration: $TIMER_SECS s)"

  # take the cols of the terminal and subtract the length of the right text
  HR_LENGTH=$(($(tput cols) - ${#RIGHT_TEXT} - 1))

  PS1_HR=$(printf %${HR_LENGTH}s)
  PS1_HR=${PS1_HR// /─}

  TEXT_PATH=$(pwd)

  # Check for VCS type and ref by checking for .git or .hg directories
  # to bypass invoking git/hg each time the prompt is drawn.
  DIR="${TEXT_PATH}"
  while [ "$DIR" != "." ] && [ "$DIR" != "/" ]; do
    if [ -d "${DIR}/.git" ]; then
      VCS_TYPE="git"
      VCS_REF=$(git -C "${DIR}" rev-parse --abbrev-ref HEAD)
      break
    elif [ -d "${DIR}/.hg" ]; then
      VCS_TYPE="hg"
      if [ -f "${DIR}/.hg/bookmarks.current" ]; then
        # if bookmarks.current exists, use that as the ref to avoid
        # invoking mercurial each time
        VCS_REF=$(cat "${DIR}/.hg/bookmarks.current")
      else
        # otherwise, fall back to using mercurial to get the current
        # ref sha.
        VCS_REF=$(hg -R "${DIR}" id -i)
      fi
      break
    fi
    DIR=$(dirname "$DIR")
  done

  # If current directory belongs to a VCS, split the path into the
  # repo root and the subdir within the repo.
  if [ -n "${VCS_TYPE-}" ]; then
    VCS_PATH="${TEXT_PATH##"$DIR"}"
    VCS_PATH="${VCS_PATH##/}"
    TEXT_PATH="${DIR}"
  fi

  # Replace $HOME with ~ in the path to emulate the default bash prompt
  TEXT_PATH="${TEXT_PATH/#$HOME/\~}"

  # To make building the prompt easier, we can define some variables
  # for the colors and text we want to use.
  COL_RESET='\[\033[0m\]'
  COL_DARK_GRAY='\[\033[1;30m\]'
  COL_GREEN='\[\033[0;32m\]'
  COL_CYAN='\[\033[0;36m\]'
  COL_YELLOW='\[\033[0;33m\]'

  TEXT_USER='\u'
  TEXT_HOST='\h'

  # Create an array to hold the lines of the prompt
  LINES=()

  # First Line: Time, Horizontal Line, Exit Code, Duration
  LINES+=("${COL_DARK_GRAY}${PS1_HR} ${RIGHT_TEXT}${COL_RESET}")

  # Third Line: User, Host, Path or VCS repo root
  LINES+=("${COL_GREEN}${TEXT_USER}@${TEXT_HOST}${COL_RESET}:${COL_CYAN}${TEXT_PATH}${COL_RESET}")

  # Fourth Line: VCS Ref, subdir within repo (if applicable)
  if [ -n "${VCS_TYPE-}" ]; then
    LINES+=("${COL_YELLOW}${VCS_TYPE} ${COL_GREEN}${VCS_REF}${COL_RESET}:${COL_CYAN}${VCS_PATH}${COL_RESET}")
  fi

  # Fifth Line: Prompt
  LINES+=("$ ")

  # combine LINES into a single string to become the prompt
  PS1="$(printf "%s\\n" "${LINES[@]}")"

  # clear TIMER to ensure the timestamp is recorded when the next
  # command is run, and clear exit code to avoid polluting environment
  unset TIMER EXIT_CODE
}

export PROMPT_COMMAND='__prompt_command'
