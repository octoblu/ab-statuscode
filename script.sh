#!/bin/bash

SCRIPT_NAME='ab-statuscode'
DIE_NOW='false'

trap 'DIE_NOW=true;' SIGINT SIGTERM

matches_debug() {
  if [ -z "$DEBUG" ]; then
    return 1
  fi
  if [ "$DEBUG" == "*" ]; then
    return 0
  fi
  if [[ $SCRIPT_NAME == "$DEBUG" ]]; then
    return 0
  fi
  return 1
}

debug() {
  local cyan='\033[0;36m'
  local no_color='\033[0;0m'
  local message="$@"
  matches_debug || return 0
  (>&2 echo -e "[${cyan}${SCRIPT_NAME}${no_color}]: $message")
}

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

assert_required_params() {
  local url="$1"

  if [ -n "$url" ]; then
    return 0
  fi

  usage

  if [ -z "$url" ]; then
    echo "Missing \$URL argument"
  fi

  exit 1
}

usage(){
  local n url
  echo "USAGE: ${SCRIPT_NAME}"
  echo ''
  echo "Description: Will hit up \$URL \$N times"
  echo ''
  echo 'Arguments:'
  echo '  -h, --help       print this help text'
  echo '  -v, --version    print the version'
  echo ''
  echo 'Environment:'
  echo '  DEBUG            print debug output'
  echo '  N                number of requests'
  echo '  URL              the URL to hit up'
  echo '  DELAY_SECONDS    time between ab tests'
  echo ''
}

version(){
  local directory
  directory="$(script_directory)"

  if [ -f "$directory/VERSION" ]; then
    cat "$directory/VERSION"
  else
    echo "unknown-version"
  fi
}

main(){
  local n url delay
  # Define args up here
  while [ "$1" != "" ]; do
    local param="$1"
    # local value="$2"
    case "$param" in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        ;;
    esac
    shift
  done

  url="$URL"
  n="$N"
  delay="$DELAY_SECONDS"

  n=${n:-1000}
  delay=${delay:-100}

  assert_required_params "$url"

  while true; do
    if [ "$DIE_NOW" == 'true' ]; then
      exit 0
    fi
    debug "hitting up \"$url\" $n times"
    ab -n "$n" -c "$n" -k "$url/" || continue
    debug "sleeping for $delay"
    sleep "$delay"
  done
}

main "$@"
