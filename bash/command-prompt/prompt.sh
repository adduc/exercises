#!/bin/bash

set -o errexit -o pipefail -o nounset

# bash will emit a DEBUG signal prior to executing any command. We can
# use this to record the start time of the command.
trap 'TIMER=${TIMER:-$EPOCHREALTIME}' DEBUG

__prompt_command() {
  # grab exit code of last command
  local EXIT_CODE=$?

  # determine duration of last command
  local TIMER_SECS=$(echo "($EPOCHREALTIME - $TIMER)" | bc)

  # limit decimal places to 2 and add comma to thousands
  local TIMER_SECS=$(printf "%'.3f" $TIMER_SECS)

  # clear TIMER to ensure the timestamp is recorded when the next
  # command is run
  unset TIMER

  # To make building the prompt easier, we can define some variables
  # for the colors and text we want to use.
  local COL_RESET='\[\033[0m\]'
  local COL_DARK_GRAY='\[\033[1;30m\]'
  local COL_GREEN='\[\033[0;32m\]'
  local COL_CYAN='\[\033[0;36m\]'

  local TEXT_USER='\u'
  local TEXT_HOST='\h'
  local TEXT_PATH='\w'
  local TEXT_TIME="$(date +%H:%M:%S)"

  # Create an array to hold the lines of the prompt
  local LINES=()

  local LEFT_TEXT="${TEXT_TIME}"

  # Build prompt text for the last command's execution
  local RIGHT_TEXT="(exit: $EXIT_CODE) (duration: $TIMER_SECS s)"

  # take the cols of the terminal and subtract the length of the left and right text
  local HR_LENGTH=$(expr $(tput cols) - ${#LEFT_TEXT} - ${#RIGHT_TEXT} - 2)

  local PS1_HR=$(printf %${HR_LENGTH}s)
  PS1_HR=${PS1_HR// /─}

  LINES+=()

  # First Line: Time, Horizontal Line, Exit Code, Duration
  LINES+=("${COL_DARK_GRAY}${LEFT_TEXT} ${PS1_HR} ${RIGHT_TEXT}${COL_RESET}")

  # Third Line: User, Host, Path
  LINES+=("${COL_GREEN}${TEXT_USER}@${TEXT_HOST}${COL_RESET}:${COL_CYAN}${TEXT_PATH}${COL_RESET}")

  # Fourth Line: Prompt
  LINES+=("$ ")

  # combine LINES into a single string
  LINES=$(printf "%s\\n" "${LINES[@]}")

  export PS1="$LINES"
}

export PROMPT_COMMAND='__prompt_command'
