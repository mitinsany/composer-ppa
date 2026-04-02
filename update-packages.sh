#!/usr/bin/env bash

set -uo pipefail

CHANGELOGS_DIR="changelogs/main/c/composer"
RELEASES_API_BASE="https://api.github.com/repos/composer/composer/releases"

function update_package_version {
    local package
    local new_version
    local download_url
    local package_json
    local preinstall
    package="$1"
    new_version="$2"
    download_url="$3"
    package_json="${package}/package.json"
    preinstall="${package}/preinstall"

    jq ".version = \"${new_version}\"" "${package_json}" > version-update.json
    mv version-update.json "${package_json}"

    sed -i "/wget/s|https://[^\"]*|${download_url}|" "${preinstall}"
}

function compare_version {
    dpkg --compare-versions "$1" lt "$2"
}

function is_strict_stable_version {
    local version="$1"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function ensure_changelogs_dir {
    mkdir -p "${CHANGELOGS_DIR}"
}

function require_non_empty_release_body {
    local release_body="$1"
    grep -q '[^[:space:]]' <<< "${release_body}"
}

function write_public_changelog {
    local version="$1"
    local release_body="$2"
    local changelog_path="${CHANGELOGS_DIR}/composer_${version}"
    printf "%s\n" "${release_body}" > "${changelog_path}"
}

function github_api_get {
    local url="$1"
    local body_file="$2"

    local headers_file
    local http_code
    headers_file="$(mktemp)"

    http_code="$(curl -sS -L -D "${headers_file}" -o "${body_file}" -w "%{http_code}" "${url}" || true)"

    if [ "${http_code}" = "200" ]; then
        rm -f "${headers_file}"
        return 0
    fi

    if [ "${http_code}" = "403" ] && grep -qi '^x-ratelimit-remaining: 0' "${headers_file}"; then
        >&2 echo "[E] GitHub API rate limit exceeded for ${url}"
        >&2 grep -i '^x-ratelimit-reset:' "${headers_file}" || true
    else
        >&2 echo "[E] GitHub API request failed (${http_code}) for ${url}"
    fi

    rm -f "${headers_file}"
    return 1
}

function process_git_releases_page {
    local page="$1"

    local releases_json
    releases_json="$(mktemp)"
    github_api_get "${RELEASES_API_BASE}?per_page=100&page=${page}" "${releases_json}" || {
        rm -f "${releases_json}"
        return 1
    }

    local releases_count
    releases_count="$(jq '. | length' "${releases_json}")"
    if [ "${releases_count}" -eq 0 ]; then
        rm -f "${releases_json}"
        return 2
    fi

    find packages/* -maxdepth 1 -mindepth 1 -type d -print0 | while read -d $'\0' PACKAGE_DIR
    do
        local PACKAGE_JSON="${PACKAGE_DIR}/package.json"

        local CODE
        CODE="$(jq --raw-output --exit-status ".code" "${PACKAGE_JSON}")"
        if [ -z "${CODE}" ]; then
            >&2 echo "[E] Cannot find 'code' key within ${PACKAGE_JSON}"
            continue
        fi

        if [ ! -f "${PACKAGE_JSON}" ]; then
            >&2 echo "[E] Cannot find ${PACKAGE_JSON}"
            continue
        fi

        local VERSION_REGEXP
        VERSION_REGEXP="$(jq --raw-output --exit-status ".version_regexp" "${PACKAGE_JSON}")"

        for (( i=0; i < releases_count; i++ ))
        do
            local DRAFT
            local PRERELEASE
            local TAG_VERSION
            local RELEASE_NAME
            local REMOTE_VERSION
            local LOCAL_VERSION
            local DOWNLOAD_URL
            local SIZE
            local RELEASE_BODY

            DRAFT="$(jq --raw-output --exit-status ".[${i}].draft" "${releases_json}")"
            PRERELEASE="$(jq --raw-output --exit-status ".[${i}].prerelease" "${releases_json}")"
            TAG_VERSION="$(jq --raw-output --exit-status ".[${i}].tag_name // \"\"" "${releases_json}")"
            RELEASE_NAME="$(jq --raw-output --exit-status ".[${i}].name // \"\"" "${releases_json}")"
            REMOTE_VERSION="${TAG_VERSION}"
            [ -z "${REMOTE_VERSION}" ] && REMOTE_VERSION="${RELEASE_NAME}"
            LOCAL_VERSION="$(jq --raw-output --exit-status ".version" "${PACKAGE_JSON}")"
            DOWNLOAD_URL="$(jq --raw-output --exit-status ".[${i}].assets[0].browser_download_url // \"\"" "${releases_json}")"
            SIZE="$(jq --raw-output --exit-status ".[${i}].assets[0].size // 0" "${releases_json}")"
            RELEASE_BODY="$(jq --raw-output --exit-status ".[${i}].body // \"\"" "${releases_json}")"

            if [[ ${DRAFT} == true || ${PRERELEASE} == true ]]; then
                >&2 printf "[I] %3s Draft/Prerelease version: %10s. Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if [ -z "${LOCAL_VERSION}" ] || [ -z "${REMOTE_VERSION}" ]; then
                >&2 echo "[E] Both 'LOCAL_VERSION' and 'REMOTE_VERSION' must be set. Probably a curl / jq error."
                continue
            fi

            if [ -z "${TAG_VERSION}" ]; then
                >&2 printf "[E] %3s: Missing tag_name for release (%10s). Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if [ -z "${DOWNLOAD_URL}" ] || [ "${SIZE}" -le 0 ]; then
                >&2 printf "[E] %3s: Missing release asset for version (%10s). Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if ! require_non_empty_release_body "${RELEASE_BODY}"; then
                >&2 printf "[E] %3s: Release notes are empty for version (%10s). Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if ! is_strict_stable_version "${REMOTE_VERSION}"; then
                >&2 printf "[I] %3s: Non-stable version (%10s) -> Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if [[ ${REMOTE_VERSION} != ${VERSION_REGEXP} ]]; then
                >&2 printf "[I] %3s: Regexp (%10s) == Remote (%10s) -> Skipped, because regexp.\n" "${CODE}" "${VERSION_REGEXP}" "${REMOTE_VERSION}"
                continue
            fi

            if ! compare_version "${LOCAL_VERSION}" "${REMOTE_VERSION}"; then
                >&2 printf "[I] %3s: Local (%10s) == Remote (%10s) -> Skipped, low version.\n" "${CODE}" "${LOCAL_VERSION}" "${REMOTE_VERSION}"
                continue
            fi

            printf "[I] %3s: Local (%10s) != Remote (%10s) -> Updating.\n" "${CODE}" "${LOCAL_VERSION}" "${REMOTE_VERSION}"

            ensure_changelogs_dir
            write_public_changelog "${REMOTE_VERSION}" "${RELEASE_BODY}"
            update_package_version "${PACKAGE_DIR}" "${REMOTE_VERSION}" "${DOWNLOAD_URL}"

            local CHANGELOG_FILENAME="changelog-composer-${REMOTE_VERSION}.dsc"
            [ -f "${CHANGELOG_FILENAME}" ] && rm "${CHANGELOG_FILENAME}"
            printf "%s\n" "${RELEASE_BODY}" > "/tmp/${CHANGELOG_FILENAME}"

            ./build-single-deb.sh "${PACKAGE_DIR}" "${CHANGELOG_FILENAME}" "${SIZE}"
            STABILITY="$(echo "${PACKAGE_DIR}" | cut -d/ -f2)"
            DEB_FILE="$(ls -c /tmp/*.deb | head -n 1)"
            reprepro --outdir ./deb --ignore=unknownfield -C main includedeb "${STABILITY}" "${DEB_FILE}"
            echo "Upgrade ${CODE}: ${LOCAL_VERSION} -> ${REMOTE_VERSION}" >> "commit.txt"
        done
    done

    rm -f "${releases_json}"
    return 0
}

[ -f "commit.txt" ] && rm -f "commit.txt"

page=1
while true; do
    process_git_releases_page "${page}"
    status=$?
    if [ "${status}" -eq 2 ]; then
        break
    fi
    if [ "${status}" -ne 0 ]; then
        >&2 echo "[E] Cannot process releases page ${page}."
        exit 1
    fi
    page=$((page + 1))
done

reprepro --outdir ./deb --ignore=unknownfield export latest stable v1
./scripts/update-release-changelogs.sh
