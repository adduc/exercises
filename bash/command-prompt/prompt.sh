#!/bin/bash

set -o errexit -o pipefail -o nounset

# bash will emit a DEBUG signal prior to executing any command. We can
# use this to record the start time of the command.
trap 'TIMER=${TIMER:-$EPOCHREALTIME}' DEBUG

__prompt_command() {
  # grab exit code of last command
  EXIT_CODE=$?

  local TIMER_SECS COL_RESET COL_DARK_GRAY COL_GREEN COL_CYAN \
    TEXT_USER TEXT_HOST TEXT_PATH TEXT_TIME LINES LEFT_TEXT RIGHT_TEXT \
    HR_LENGTH PS1_HR

  # determine duration of last command
  TIMER_SECS=$(echo "($EPOCHREALTIME - $TIMER)" | bc)

  # limit decimal places to 3 and add comma to thousands
  TIMER_SECS=$(printf "%'.3f" "$TIMER_SECS")


  # To make building the prompt easier, we can define some variables
  # for the colors and text we want to use.
  COL_RESET='\[\033[0m\]'
  COL_DARK_GRAY='\[\033[1;30m\]'
  COL_GREEN='\[\033[0;32m\]'
  COL_CYAN='\[\033[0;36m\]'

  TEXT_USER='\u'
  TEXT_HOST='\h'
  TEXT_PATH='\w'
  TEXT_TIME="$(date +%H:%M:%S)"

  # Create an array to hold the lines of the prompt
  LINES=()

  LEFT_TEXT="${TEXT_TIME}"

  # Build prompt text for the last command's execution
  RIGHT_TEXT="(exit: $EXIT_CODE) (duration: $TIMER_SECS s)"

  # take the cols of the terminal and subtract the length of the left and right text
  HR_LENGTH=$(($(tput cols) - ${#LEFT_TEXT} - ${#RIGHT_TEXT} - 2))

  PS1_HR=$(printf %${HR_LENGTH}s)
  PS1_HR=${PS1_HR// /─}

  LINES+=()

  # First Line: Time, Horizontal Line, Exit Code, Duration
  LINES+=("${COL_DARK_GRAY}${LEFT_TEXT} ${PS1_HR} ${RIGHT_TEXT}${COL_RESET}")

  # Third Line: User, Host, Path
  LINES+=("${COL_GREEN}${TEXT_USER}@${TEXT_HOST}${COL_RESET}:${COL_CYAN}${TEXT_PATH}${COL_RESET}")

  # Fourth Line: Prompt
  LINES+=("$ ")

  # combine LINES into a single string to become the prompt
  PS1="$(printf "%s\\n" "${LINES[@]}")"

  # clear TIMER to ensure the timestamp is recorded when the next
  # command is run, and clear exit code to avoid polluting environment
  unset TIMER EXIT_CODE
}

export PROMPT_COMMAND='__prompt_command'
