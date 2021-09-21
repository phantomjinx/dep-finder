#!/usr/bin/env bash

# Copyright (C) 2021 Paul Richardson
# This file is part of dep-finder <https://github.com/phantomjinx/dep-finder>.
#
# dep-finder is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dep-finder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dep-finder.  If not, see <http://www.gnu.org/licenses/>.

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
