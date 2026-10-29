#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${ROOT_DIR}/scripts"
CHANGELOGS_DIR="${ROOT_DIR}/changelogs/main/c/composer"
DEBIAN_REVISION="2"
source "${SCRIPT_DIR}/github-api.sh"

update_package_template() {
    local package_dir="$1"
    local package_version="$2"
    local upstream_version="$3"
    local download_url="$4"
    local download_sha256="$5"
    local package_json="${package_dir}/package.json"

    jq \
        --arg version "${package_version}" \
        --arg upstream_version "${upstream_version}" \
        --arg download_url "${download_url}" \
        --arg download_sha256 "${download_sha256}" \
        '.version = $version
            | .upstream_version = $upstream_version
            | .download_url = $download_url
            | .download_sha256 = $download_sha256' \
        "${package_json}" > "${package_json}.tmp"
    mv "${package_json}.tmp" "${package_json}"
}

compare_version() {
    dpkg --compare-versions "$1" lt "$2"
}

package_needs_update() {
    local local_version="$1"
    local remote_version="$2"
    local local_sha256="$3"
    local package_file="$4"

    if compare_version "${local_version}" "${remote_version}"; then
        return 0
    fi
    if dpkg --compare-versions "${local_version}" eq "${remote_version}" \
        && { ! [[ "${local_sha256}" =~ ^[0-9a-f]{64}$ ]] || [ ! -f "${package_file}" ]; }; then
        return 0
    fi
    return 1
}

is_strict_stable_version() {
    local version="$1"
    [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

require_non_empty_release_body() {
    local release_body="$1"
    grep -q '[^[:space:]]' <<< "${release_body}"
}

write_public_changelog() {
    local version="$1"
    local release_body="$2"
    mkdir -p "${CHANGELOGS_DIR}"
    printf "%s\n" "${release_body}" > "${CHANGELOGS_DIR}/composer_${version}"
}

version_matches_channel_pattern() {
    local version="$1"
    local pattern="$2"
    local major minor patch

    IFS='.' read -r major minor patch <<< "${version}"

    if [[ "${pattern}" =~ ^([0-9]+)\.\*\.\*$ ]]; then
        [ "${major}" = "${BASH_REMATCH[1]}" ]
        return
    fi
    if [[ "${pattern}" =~ ^([0-9]+)\.([0-9]+)\.\*$ ]]; then
        [ "${major}" = "${BASH_REMATCH[1]}" ] && [ "${minor}" = "${BASH_REMATCH[2]}" ]
        return
    fi
    if [[ "${pattern}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        [ "${major}" = "${BASH_REMATCH[1]}" ] && [ "${minor}" = "${BASH_REMATCH[2]}" ] && [ "${patch}" = "${BASH_REMATCH[3]}" ]
        return
    fi

    [[ "${version}" == ${pattern} ]]
}

download_composer_phar() {
    local download_url="$1"
    local artifact
    artifact="$(mktemp)"

    if ! curl -fL --retry 3 --connect-timeout 15 "${download_url}" -o "${artifact}"; then
        rm -f "${artifact}"
        return 1
    fi

    printf '%s\n' "${artifact}"
}

process_git_releases_page() {
    local page="$1"
    local releases_json
    local releases_count

    releases_json="$(mktemp)"
    if ! github_releases_page_json "${page}" > "${releases_json}"; then
        rm -f "${releases_json}"
        return 1
    fi

    releases_count="$(jq '. | length' "${releases_json}")"
    if [ "${releases_count}" -eq 0 ]; then
        rm -f "${releases_json}"
        return 2
    fi

    for package_json in packages/*/composer/package.json; do
        local package_dir
        local code
        local version_pattern
        package_dir="$(dirname "${package_json}")"
        code="$(jq --raw-output --exit-status '.code' "${package_json}")"
        version_pattern="$(jq --raw-output --exit-status '.version_regexp' "${package_json}")"

        for ((i=0; i < releases_count; i++)); do
            local draft prerelease remote_version remote_package_version
            local local_version local_sha256 download_url release_body package_file
            local artifact download_sha256 changelog_filename channel deb_file

            draft="$(jq --raw-output --exit-status ".[${i}].draft" "${releases_json}")"
            prerelease="$(jq --raw-output --exit-status ".[${i}].prerelease" "${releases_json}")"
            remote_version="$(jq --raw-output --exit-status ".[${i}].tag_name // \"\"" "${releases_json}")"
            download_url="$(jq --raw-output --exit-status ".[${i}] | [.assets[]? | select(.name == \"composer.phar\")][0].browser_download_url // \"\"" "${releases_json}")"
            release_body="$(jq --raw-output --exit-status ".[${i}].body // \"\"" "${releases_json}")"
            local_version="$(jq --raw-output --exit-status '.version' "${package_json}")"
            local_sha256="$(jq --raw-output '.download_sha256 // ""' "${package_json}")"
            remote_package_version="${remote_version}-${DEBIAN_REVISION}"
            package_file="deb/pool/main/c/composer/composer_${remote_package_version}_amd64.deb"

            if [ "${draft}" = true ] || [ "${prerelease}" = true ]; then
                continue
            fi
            if [ -z "${remote_version}" ] || ! is_strict_stable_version "${remote_version}"; then
                continue
            fi
            if ! version_matches_channel_pattern "${remote_version}" "${version_pattern}"; then
                continue
            fi
            if [ -z "${download_url}" ]; then
                >&2 printf "[E] %s: composer.phar asset is missing for %s.\n" "${code}" "${remote_version}"
                rm -f "${releases_json}"
                return 1
            fi
            if ! require_non_empty_release_body "${release_body}"; then
                >&2 printf "[E] %s: Release notes are empty for %s.\n" "${code}" "${remote_version}"
                rm -f "${releases_json}"
                return 1
            fi
            if ! package_needs_update "${local_version}" "${remote_package_version}" "${local_sha256}" "${package_file}"; then
                >&2 printf "[I] %s: Local (%s) >= Remote (%s). Skipped.\n" "${code}" "${local_version}" "${remote_package_version}"
                break
            fi

            printf "[I] %s: Local (%s) -> Remote (%s). Updating.\n" "${code}" "${local_version}" "${remote_package_version}"
            artifact="$(download_composer_phar "${download_url}")"
            download_sha256="$(sha256sum "${artifact}" | awk '{print $1}')"
            rm -f "${artifact}"

            write_public_changelog "${remote_package_version}" "${release_body}"
            update_package_template "${package_dir}" "${remote_package_version}" "${remote_version}" "${download_url}" "${download_sha256}"

            changelog_filename="changelog-composer-${remote_package_version}.dsc"
            printf "%s\n" "${release_body}" > "/tmp/${changelog_filename}"
            deb_file="/tmp/composer_${remote_package_version}_amd64.deb"
            rm -f "${deb_file}"
            "${SCRIPT_DIR}/build-single-deb.sh" "${package_dir}" "${changelog_filename}"
            channel="$(basename "$(dirname "${package_dir}")")"
            reprepro --outdir ./deb --ignore=unknownfield -C main includedeb "${channel}" "${deb_file}"
            echo "Upgrade ${code}: ${local_version} -> ${remote_package_version}" >> commit.txt
            break
        done
    done

    rm -f "${releases_json}"
}

main() {
    local page=1
    local status

    cd "${ROOT_DIR}"
    [ -f commit.txt ] && rm -f commit.txt

    while true; do
        if process_git_releases_page "${page}"; then
            status=0
        else
            status=$?
        fi
        if [ "${status}" -eq 2 ]; then
            break
        fi
        if [ "${status}" -ne 0 ]; then
            >&2 echo "[E] Cannot process releases page ${page}."
            exit 1
        fi
        page=$((page + 1))
    done

    if [ -s commit.txt ]; then
        reprepro --outdir ./deb --ignore=unknownfield export latest stable v1
        "${SCRIPT_DIR}/update-release-changelogs.sh"
    else
        echo "[I] No package updates detected. Skipping repository metadata export/sign."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
