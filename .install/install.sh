#!/usr/bin/env bash
fail () {
  printf '%s\n' "$1" >&2 ## Send message to stderr.
  exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

checkBin () { command -v "$1" &> /dev/null ;}
require () { checkBin "$1" || fail "Executable for $1 is missing" ;}
installing () { echo "Starting to install $1 ";}

EXEC_DIR="$HOME/.local/bin"

# One password
one_password_ () {
  OP_VERSION="1.12.4"
  url="https://cache.agilebits.com/dist/1P/op/pkg/v${OP_VERSION}/op_linux_arm_v${OP_VERSION}.zip"
  curl -sS -o 1password.zip "$url"
  unzip 1password.zip op -d "$EXEC_DIR"
  rm -f 1password.zip

}

if ! checkBin "op"
then
  require "unzip"
  require "curl"
  installing "One Password"
  one_password_
fi
