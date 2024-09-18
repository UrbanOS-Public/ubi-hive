#!/bin/bash

set -exv

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo $SCRIPT_DIR
IMAGE_REPO="quay.io"
ORG="urbanos"
APP="ubi-hive"
IMAGE="${IMAGE_REPO}/${ORG}/${APP}"
IMAGE_TAG_DEFAULT="$(${SCRIPT_DIR}/get_image_tag.sh)-hadoop-3.3.6"
IMAGE_TAG_AMD="$(${SCRIPT_DIR}/get_image_tag.sh)-hadoop-3.3.6-amd"
echo $(${SCRIPT_DIR}/get_image_tag.sh)
export ACCESS_TOKEN=$1

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

if [[ -z "$1" ]]; then
    echo "User must provide access token as first argument:"
    echo "./build_deploy.sh access-token"
    exit 1
fi

# Create tmp dir to store data in during job run (do NOT store in $WORKSPACE)
export TMP_JOB_DIR=$(mktemp -d -p "$HOME" -t "jenkins-${JOB_NAME}-${BUILD_NUMBER}-XXXXXX")
echo "job tmp dir location: $TMP_JOB_DIR"

function job_cleanup() {
    echo "cleaning up job tmp dir: $TMP_JOB_DIR"
    rm -fr $TMP_JOB_DIR
}

trap job_cleanup EXIT ERR SIGINT SIGTERM

DOCKER_CONF="$TMP_JOB_DIR/.docker"
mkdir -p "$DOCKER_CONF"
docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG_DEFAULT}" ${SCRIPT_DIR} --secret id=ACCESS_TOKEN --progress=plain --no-cache
docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG_DEFAULT}"

docker --config="$DOCKER_CONF" build -t "${IMAGE}:${IMAGE_TAG_AMD}" ${SCRIPT_DIR} --secret id=ACCESS_TOKEN --progress=plain --no-cache --platform linux/amd64
docker --config="$DOCKER_CONF" push "${IMAGE}:${IMAGE_TAG_AMD}"

docker --config="$DOCKER_CONF" tag "${IMAGE}:${IMAGE_TAG_AMD}" "${IMAGE}:latest"
docker --config="$DOCKER_CONF" push "${IMAGE}:latest"

docker --config="$DOCKER_CONF" logout
