#!/usr/bin/env bash
# A shell script about some util functions.

hash_hmac() {
  local data="$1"
  local key="$2&"
  echo -n "$data" | openssl sha1 -binary -hmac "$key" | base64
}

join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

url_encode() {
  local str="$1"
  local strlen=${#str}
  local encoded=""
  local pos c o

  for (( pos = 0 ; pos < strlen ; pos++ )); do
    c=${str:$pos:1}
    case "$c" in
      [-_.~a-zA-Z0-9] )
        o="$c"
        ;;
      * )
        printf -v o '%%%02X' "'$c"
    esac
    encoded+="$o"
  done
  echo "$encoded"
}

random_char() {
  local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local i=$(($RANDOM % ${#chars}))
  echo -n "${chars:$i:1}"
}

random_chars() {
  local len=$1
  for i in $(seq 1 $len); do echo -n "$(random_char)"; done
}

git_pull_need() {
  if [ "$(git_pull_check)" = 'Need to pull' ]; then
    echo true
  else
    echo false
  fi
}

git_pull_check() {
  git remote update

  local upstream="@{u}"
  local locale remote base

  locale=$(git rev-parse @)
  remote=$(git rev-parse $upstream)
  base=$(git merge-base @ $upstream)

  if [ $locale = $remote ]; then
    echo "Up-to-date"
  elif [ $locale = $base ]; then
    echo "Need to pull"
  elif [ $remote = $base ]; then
    echo "Need to push"
  else
    echo "Diverged"
  fi
}

debug() {
  if [[ $DEBUG = true ]]; then
    local params=$*
    echo
    echo "$params"
    echo
  fi
}
