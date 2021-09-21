#!/usr/bin/env bash

docker_is_available() {
  set +e

  local docker=$(readopt --docker -d)
  if [ -n "${docker}" ]; then
    if [ -f "${docker}" ]; then
      echo "${docker}"
      return
    else
      echo "ERROR: docker binary specified but not valid"
      return 1
    fi
  fi

  # docker not specified so try and find it
  which docker &>/dev/null
  if [ $? -ne 0 ]; then
    set -e
    echo "ERROR: cannot find docker binary."
    return 1
  fi

  echo "docker"
}

docker_extract_jars() {
  local image="${1:-}"
  if [ -z "${image}" ]; then
    echo "ERROR: please specify the '--image' option with a valid image reference"
    return 1
  fi

  ${DOCKER} pull "${image}" > /dev/null
  if [ $? -ne 0 ]; then
    echo "ERROR: failed to pull the image ${image}"
    return 1
  fi

  local workDir=$(${DOCKER} inspect --format='{{.GraphDriver.Data.WorkDir}}' "${image}")
  if [ ! -d "${workDir}" ]; then
    echo "ERROR: cannot access or locate work directory '${workDir}' of image ${image}"
    return 1
  fi

  # Find all jars in the parent of the working directory
  local jars=$(find "${workDir}/.." -name "*.jar")
  if [ -z "${jars}" ]; then
    echo "ERROR: No jars can be found in this image"
    return 1
  fi

  echo "${jars}" | sort | uniq
}

do_image() {
  local image="${1:-}"
  local jars=$(docker_extract_jars "${image}")
  if [ "$(contains_error ${jars})" == "YES" ]; then
    echo "${jars}"
    exit 1
  fi

  if [ $(hasflag --jar -j) ]; then
    local jar=$(readopt --jar -j)
    jar=$(echo "${jars}" | sed -n -e "s/\(.*${jar}.*\)/\1/p")
    do_jar "${jar}" "${jars}"
  else
    echo
    echo "======================================="
    echo "List of jar archives in image"
    echo "======================================="
    for jar in ${jars}
    do
      echo $(basename ${jar})
    done
  fi
}
