#!/usr/bin/env bash

#set -euxo pipefail

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

    # package.json
    jq ".version = \"${new_version}\"" "${package_json}" > version-update.json
    mv version-update.json "${package_json}"

    # preinstall
    sed -i "/wget/s|https://[^\"]*|${download_url}|" "${preinstall}"
}

function compare_version() {
    dpkg --compare-versions $1 lt $2
}

function process_git_releases_page() {
    local PAGE="$1"
    local COMMIT_FILE=commit.txt
    [ -f "$COMMIT_FILE" ] && rm -f "$COMMIT_FILE"

    local RELEASES_JSON="releases.json"
    curl -sfLo "${RELEASES_JSON}" "https://api.github.com/repos/composer/composer/releases?page=${PAGE}" || return 1
    local RELEASES_COUNT="$(jq '. | length' ${RELEASES_JSON})"

    find packages/* -maxdepth 1 -mindepth 1 -type d -print0 | while read -d $'\0' PACKAGE_DIR
    do
        local PACKAGE_JSON="${PACKAGE_DIR}/package.json"

        local CODE="$(jq --raw-output --exit-status ".code" "${PACKAGE_JSON}")"
        if [ -z "${CODE}" ]; then
            >&2 echo "[E] Cannot find 'code' key within ${PACKAGE_JSON}"
            continue
        fi

        if [ ! -f "${PACKAGE_JSON}" ]; then
            >&2 echo "[E] Cannot find ${PACKAGE_JSON}"
            continue
        fi

        local VERSION_REGEXP="$(jq --raw-output --exit-status ".version_regexp" "${PACKAGE_JSON}")"

        for (( i=0; i < ${RELEASES_COUNT}; i++ ))
        do
            local PRERELEASE="$(jq --raw-output --exit-status ".[${i}].prerelease" "${RELEASES_JSON}")"
            local REMOTE_VERSION="$(jq --raw-output --exit-status ".[${i}].name" "${RELEASES_JSON}")"
            local LOCAL_VERSION="$(jq --raw-output --exit-status ".version" "${PACKAGE_JSON}")"
            local DOWNLOAD_URL="$(jq --raw-output --exit-status ".[${i}].assets[0].browser_download_url" "${RELEASES_JSON}")"
            local SIZE="$(jq --raw-output --exit-status ".[${i}].assets[0].size" "${RELEASES_JSON}")"

            if [[ ${PRERELEASE} == true ]]; then
                >&2 printf "%3s Prerelease version: %10s. Skipped.\n" "${CODE}" "${REMOTE_VERSION}"
                continue
            fi

            if [ -z "${LOCAL_VERSION}" ] || [ -z "${REMOTE_VERSION}" ]; then
                >&2 echo "[E] Both 'LOCAL_VERSION' and 'REMOTE_VERSION' must be set. Probably a curl / jq error."
                continue
            fi

            if [[ ${REMOTE_VERSION} != ${VERSION_REGEXP} ]]; then
                >&2 printf "%3s: Regexp (%10s) == Remote (%10s) -> Skipped, because regexp.\n" "${CODE}" "${REGEXP}" "${REMOTE_VERSION}"
                continue
            fi

            compare_version ${LOCAL_VERSION} ${REMOTE_VERSION}
            if [ "$?" -gt 0 ]; then
                >&2 printf "%3s: Local (%10s) == Remote (%10s) -> Skipped, low version.\n" "${CODE}" "${LOCAL_VERSION}" "${REMOTE_VERSION}"
                continue
            fi

            printf "%3s: Local (%10s) != Remote (%10s) -> Updating.\n" "${CODE}" "${LOCAL_VERSION}" "${REMOTE_VERSION}"

            update_package_version "${PACKAGE_DIR}" "${REMOTE_VERSION}" "${DOWNLOAD_URL}"

            local CHANGELOG_FILENAME="changelog-composer-${REMOTE_VERSION}.dsc"
            [ -f "${CHANGELOG_FILENAME}" ] && rm "${CHANGELOG_FILENAME}"
            echo "$(jq --raw-output --exit-status ".[${i}].body" "${RELEASES_JSON}")" > "/tmp/${CHANGELOG_FILENAME}"

            ./build-single-deb.sh "${PACKAGE_DIR}" "${CHANGELOG_FILENAME}" "${SIZE}"
            STABILITY="$(echo "${PACKAGE_DIR}" | cut -d/ -f2)"
            DEB_FILE="$(ls -c /tmp/*.deb | head -n 1)"
            reprepro --outdir ./deb -C main includedeb "${STABILITY}" $DEB_FILE
            #reprepro --outdir ./deb -C main includedsc "${STABILITY}" /tmp/$CHANGELOG_FILENAME
            echo "Upgrade ${CODE}: ${LOCAL_VERSION} -> ${REMOTE_VERSION}" >> "$COMMIT_FILE"
        done
    done

    [ -f "${RELEASES_JSON}" ] && rm -f "${RELEASES_JSON}"
}

process_git_releases_page 1
process_git_releases_page 2
