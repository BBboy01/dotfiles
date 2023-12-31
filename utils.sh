#!/usr/bin/env bash

###
# format print
###

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    echo  "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo  "\n$COL_GREEN\[._.]/$COL_RESET - "$1
}

function running() {
    echo "$COL_YELLOW ⇒ $COL_RESET"$1": "
}

function action() {
    echo "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[warning]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET "$1
}


function log() {
  echo -e "\033[1;33m$1\033[0m"
}

function log_error() {
  echo -e "\033[1;31m$1\033[0m"
}

function log_success() {
  echo -e "\033[1;32m$1\033[0m"
}

function log_info() {
  echo -e "\033[1;35m$1\033[0m"
}

function log_with_header() {
  length=$(echo "$1" | awk '{print length}')
  delimiter=$(head -c $length </dev/zero | tr '\0' "${2:-=}")

  log_info "$delimiter"
  log_info "$1"
  log_info "$delimiter"
}

###
# convienience methods for requiring installed software
###

function require_cask() {
    running "brew install $1 --cask"
    brew cask list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew install $1 $2 --cask"
        brew install $1 --cask
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

function require_brew() {
    running "brew $1 $2"
    brew list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew install $1 $2"
        brew install $1 $2
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

function require_node(){
    running "node -v"
    node -v
    if [[ $? != 0 ]]; then
        action "node not found, installing via homebrew"
        brew install node
    fi
    ok
}

function require_npm() {
    sourceNVM
    nvm use stable
    running "npm $*"
    npm list -g --depth 0 | grep $1@ > /dev/null
    if [[ $? != 0 ]]; then
        action "npm install -g $*"
        npm install -g $@
    fi
    ok
}
