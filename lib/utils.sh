#!/usr/bin/env bash

# Read the value of an option.
readopt() {
  filters="$@"
  next=false
  for var in "${ARGS[@]}"; do
      if $next; then
          local value="${var##-}"
          if [ "$value" != "$var" ]; then
             # Next is already also option, so we haven't
             # specified a value.
             return
          fi
          echo $var
          break;
      fi
      for filter in $filters; do
          if [[ "$var" = ${filter}* ]]; then
              local value="${var//${filter}=/}"
              if [ "$value" != "$var" ]; then
                  echo $value
                  return
              fi
              next=true
          fi
      done
  done
}

hasflag() {
  filters="$@"
  for var in "${ARGS[@]}"; do
    for filter in $filters; do
      if [ "$var" = "$filter" ]; then
        echo 'true'
        return
      fi
    done
  done
}

contains_error() {
  local msg="${1:-}"

  #
  # Uppercase the msg to determine if it contains ERROR
  #
  if awk 'BEGIN {exit !index(toupper(ARGV[2]), toupper(ARGV[1]))}' "ERROR" "$1"; then
      echo "YES"
  else
      echo "NO"
  fi
}

contains() {
  local needle="${1}"
  local haystack="${2}"

  [[ ${haystack} =~ (^|[[:space:]])"${needle}"($|[[:space:]]) ]] && echo "YES" || echo "NO"
}
