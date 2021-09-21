#!/usr/bin/env bash

SCOPES="compile provided runtime test system import"
TREEFILE=$(mktemp --suffix=.out)
trap 'rm -f "${TREEFILE}"' EXIT

maven_is_available() {
  set +e

  local maven=$(readopt --maven -d)
  if [ -n "${maven}" ]; then
    if [ -f "${maven}" ]; then
      echo "${maven}"
      return
    else
      echo "ERROR: maven binary specified but not valid"
      return 1
    fi
  fi

  # maven not specified so try and find it
  which mvn &>/dev/null
  if [ $? -ne 0 ]; then
    set -e
    echo "ERROR: cannot find maven binary."
    return 1
  fi

  echo "mvn"
}

do_pom() {
  local pom="${1:-}"

  if [ -z "${pom}" ]; then
    echo "ERROR: please specify the '--pom' option with a valid pom file, ie. --pom <pom>"
    exit 1
  fi

  if [ ! -f "${pom}" ]; then
    echo "ERROR: please specify a valid pom file"
    exit 1
  fi

  ${MAVEN} dependency:tree \
    -q \
    -D appendOutput=true \
    -D outputFile=${TREEFILE} \
    -f "${pom}"

  if [ $(hasflag --full -f) ]; then
    cat ${TREEFILE}
  else
    for scope in ${SCOPES}
    do
      echo
      echo "================================="
      echo "     ${scope} dependencies"
      echo "================================="
      cat ${TREEFILE} | \
        sed -n -e "s/[|+-\\ ]\+\(.*\):\(.*\):jar:\([0-9.a-zA-Z]\+\):${scope}/\2-\3.jar/p" | \
        sort | uniq
    done
  fi
}
