#!/usr/bin/env bash

set -euxo pipefail

PACKAGE_DIR="$1"
CHANGELOG_FILE="$2"

if [ -z "${PACKAGE_DIR}" ]; then
    >&2 echo "[E] Cannot find folder ${PACKAGE_DIR}"
    exit 1
fi

PACKAGE_JSON="${PACKAGE_DIR}/package.json"
if [ ! -f "${PACKAGE_JSON}" ]; then
    >&2 echo "[E] Cannot find ${PACKAGE_JSON}"
    exit 1
fi

VERSION="$(jq --raw-output --exit-status ".version" "${PACKAGE_JSON}")"
DESCRIPTION="$(jq --raw-output --exit-status ".description" "${PACKAGE_JSON}")"

if [ -z "${VERSION}" ] || [ -z "${DESCRIPTION}" ]; then
    >&2 echo "[E] Cannot find 'version' or 'description' key within ${PACKAGE_JSON}"
    exit 1
fi

STABILITY="$(echo "${PACKAGE_DIR}" | cut -d/ -f2)"
PACKAGE_NAME="$(echo "${PACKAGE_DIR}" | cut -d/ -f3)"
OUTPUT_DIR="/tmp"
ARCH="amd64"

fpm -t deb \
    -s dir \
    -C "${PACKAGE_DIR}" \
    --name "${PACKAGE_NAME}" \
    --architecture "${ARCH}" \
    --license "MIT" \
    --maintainer "Aleksandr Mitin <mitinsoft@gmail.com>" \
    --vendor "https://getcomposer.org/" \
    --url "https://getcomposer.org/" \
    --version "${VERSION}" \
    --deb-changelog "/tmp/${CHANGELOG_FILE}" \
    --deb-upstream-changelog "/tmp/${CHANGELOG_FILE}" \
    --deb-pre-depends "wget" \
    --category "devel" \
    --package "${OUTPUT_DIR}" \
    --description "${DESCRIPTION}" \
    --before-install "${PACKAGE_DIR}/preinstall" \
    --after-install "${PACKAGE_DIR}/postinstall" \
    --after-remove "${PACKAGE_DIR}/postremove" \
    --deb-no-default-config-files \
    --exclude "package.json" \
    --exclude "postinstall" \
    --exclude "postremove" \
    --exclude "preinstall" \
    .

