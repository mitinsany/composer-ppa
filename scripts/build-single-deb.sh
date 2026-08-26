#!/usr/bin/env bash

set -euxo pipefail

PACKAGE_DIR="$1"
CHANGELOG_FILE="$2"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_DIR="${ROOT_DIR}/packages/composer-common"
PACKAGE_JSON="${PACKAGE_DIR}/package.json"
POSTINSTALL_TEMPLATE="${COMMON_DIR}/postinstall.in"
POSTREMOVE_SCRIPT="${COMMON_DIR}/postremove"

if [ ! -f "${PACKAGE_JSON}" ]; then
    >&2 echo "[E] Cannot find ${PACKAGE_JSON}"
    exit 1
fi
if [ ! -f "${POSTINSTALL_TEMPLATE}" ] || [ ! -f "${POSTREMOVE_SCRIPT}" ]; then
    >&2 echo "[E] Cannot find common package scripts"
    exit 1
fi

VERSION="$(jq --raw-output --exit-status '.version' "${PACKAGE_JSON}")"
DESCRIPTION="$(jq --raw-output --exit-status '.description' "${PACKAGE_JSON}")"
DOWNLOAD_URL="$(jq --raw-output --exit-status '.download_url' "${PACKAGE_JSON}")"
DOWNLOAD_SHA256="$(jq --raw-output --exit-status '.download_sha256' "${PACKAGE_JSON}")"
PACKAGE_NAME="composer"
ARCH="amd64"

if [ -z "${VERSION}" ] || [ -z "${DESCRIPTION}" ] || [ -z "${DOWNLOAD_URL}" ] || ! [[ "${DOWNLOAD_SHA256}" =~ ^[0-9a-f]{64}$ ]]; then
    >&2 echo "[E] Cannot find required keys within ${PACKAGE_JSON}"
    exit 1
fi

postinstall_script="$(mktemp)"
trap 'rm -f "${postinstall_script}"' EXIT
sed \
    -e "s|@DOWNLOAD_URL@|${DOWNLOAD_URL}|" \
    -e "s|@DOWNLOAD_SHA256@|${DOWNLOAD_SHA256}|" \
    "${POSTINSTALL_TEMPLATE}" > "${postinstall_script}"
chmod 0755 "${postinstall_script}"

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
    --depends "curl" \
    --category "devel" \
    --package "/tmp/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" \
    --description "${DESCRIPTION}" \
    --after-install "${postinstall_script}" \
    --after-remove "${POSTREMOVE_SCRIPT}" \
    --deb-no-default-config-files \
    --exclude "package.json" \
    .

