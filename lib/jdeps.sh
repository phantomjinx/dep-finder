#!/usr/bin/env bash

TRIAGE_DIR=$(mktemp -d)
trap 'rm -rf -- "${TRIAGE_DIR}"' EXIT

check_version() {
  local jdeps="${1:-}"
  if [ -z "${jdeps}" ]; then
    echo "ERROR: cannot check version of jdeps - not specified"
    return
  fi

  local major_version=$("${jdeps}" -version | sed -n -e 's/\([0-9]\+\).*/\1/p')
  if [ -z "${major_version}" ]; then
    echo "ERROR: cannot determine jdeps version"
    return
  fi

  if [ ${major_version} -lt ${MIN_JDEPS_VERSION} ]; then
    echo "ERROR: jdeps major version should be at least 11. Please download java 11 sdk and use --jdeps parameter"
    return
  fi

  echo "${jdeps}"
}

jdeps_is_available() {
  set +e

  local jdeps=$(readopt --jdeps)
  if [ -n "${jdeps}" ]; then
    if [ -f "${jdeps}" ]; then
      echo "$(check_version ${jdeps})"
      return
    else
      echo "ERROR: jdeps binary specified but not valid"
      return
    fi
  fi

  # jdeps not specified so try and find it
  which jdeps &>/dev/null
  if [ $? -ne 0 ]; then
    set -e
    echo "ERROR: cannot find jdeps binary. This is available as part of the Java SDK"
    return
  fi

  echo $(check_version "jdeps")
}

create_classpath() {
  local jardirectories="${1:-}"
  local cp=""
  if [ -z "${jardirectories}" ]; then
    echo "${cp}"
    return
  fi

  for j in ${jardirectories}
  do
    if [ -f "${j}" ]; then
      cp="${cp}:${j}"
    elif [ -d "${j}" ]; then
      local jars=$(find "${j}/" -type f -name '*.jar')
      cp="${cp}:$(create_classpath "${jars}")"
    fi
  done

  echo "${cp}"
}

do_jar() {
  local jarfile="${1:-}"
  local extrajars="${2:-}"

  if [ -z "${jarfile}" ]; then
    echo "ERROR: please specify the '--jar' option with a valid jar file, ie. --jar <jar>"
    exit 1
  fi

  if [ ! -f "${jarfile}" ]; then
    echo "ERROR: please specify a valid jar file"
    exit 1
  fi

  cp "${jarfile}" ${TRIAGE_DIR}/
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy jar to triage directory"
    exit 1
  fi

  pushd "${TRIAGE_DIR}" > /dev/null

  jarfile="$(basename ${jarfile})"
  if [ ! -f "${jarfile}" ]; then
    echo "ERROR: Failed to detect jar in triage directory"
    exit 1
  fi

  jar xvf "${jarfile}" &> /dev/null
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract files from jar"
    exit 1
  fi

  local CLASSPATH=$(create_classpath "$(find "${TRIAGE_DIR}" -type f -name '*.jar')")
  if [ -n "${extrajars}" ]; then
    CLASSPATH="${CLASSPATH}:$(create_classpath "${extrajars}")"
  fi

  if [ $(hasflag --repo -r) ]; then
    CLASSPATH="${CLASSPATH}:$(create_classpath "$(readopt --repo -r)")"
  fi

  if [ $(hasflag --classpath -cp) ]; then
    CLASSPATH="${CLASSPATH}:$(readopt --classpath -cp))"
  fi

  echo "Using jdeps version: $(${JDEPS} -version)"
  echo "Extracting and analysing ${jarfile}"

  local jars=$(${JDEPS} \
    -recursive \
    --multi-release base \
    -cp "${CLASSPATH}" \
    "${jarfile}")

  if [ $(hasflag --full -f) ]; then
    echo "${jars}"
  else
    jars=$(echo "${jars}" | \
    sed -n -e 's/.*[ |\/]\(.*\.jar\).*/\1/p' | \
    sed "/${jarfile}/d" |
    sort | uniq)

    echo
    echo "================================="
    echo "Compile-time dependencies"
    echo "================================="
    echo "${jars}"
  fi

  echo
  echo "============================================"
  echo "Additional jars on classpath (maybe runtime)"
  echo "============================================"

  #
  # Search the classpath jars and list all those
  # not already listed as they are runtime dependencies
  #

  for cpjar in ${CLASSPATH//:/ }
  do
    j=$(basename "${cpjar}")

    if [ "${j}" == "${jarfile}" -o $(contains "${j}" "${jars}") == "YES" ]; then
      continue
    fi

    echo "${j}"
  done

  popd >/dev/null
}
