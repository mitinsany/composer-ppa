#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOGS_DIR="${ROOT_DIR}/changelogs/main/c/composer"
CHANNELS=(latest stable v1)
MODE="${1:---current}"
RELEASES_API_BASE="https://api.github.com/repos/composer/composer/releases"

require_non_empty_release_body() {
    local release_body="$1"
    grep -q '[^[:space:]]' <<< "${release_body}"
}

release_matches_current_versions() {
    local version="$1"
    shift
    local current_versions=("$@")
    local current
    for current in "${current_versions[@]}"; do
        if [ "${version}" = "${current}" ]; then
            return 0
        fi
    done
    return 1
}

github_api_get() {
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

mkdir -p "${CHANGELOGS_DIR}"

if [ "${MODE}" != "--current" ] && [ "${MODE}" != "--all" ]; then
    >&2 echo "[E] Unknown mode: ${MODE}. Use --current or --all."
    exit 1
fi

if [ "${MODE}" = "--all" ]; then
    rm -f "${CHANGELOGS_DIR}"/composer_*
fi

current_versions=()
if [ "${MODE}" = "--current" ]; then
    for channel in "${CHANNELS[@]}"; do
        package_json="${ROOT_DIR}/packages/${channel}/composer/package.json"
        version="$(jq --raw-output --exit-status ".version" "${package_json}")"
        if [ -z "${version}" ]; then
            >&2 echo "[E] Cannot read version from ${package_json}"
            exit 1
        fi
        current_versions+=("${version}")
    done
fi

page=1
written=0
while true; do
    releases_json="$(mktemp)"
    github_api_get "${RELEASES_API_BASE}?per_page=100&page=${page}" "${releases_json}" || {
        rm -f "${releases_json}"
        exit 1
    }
    releases_count="$(jq '. | length' "${releases_json}")"
    if [ "${releases_count}" -eq 0 ]; then
        rm -f "${releases_json}"
        break
    fi

    while read -r release; do
        version="$(jq --raw-output --exit-status ".tag_name" <<< "${release}")"
        release_body="$(jq --raw-output --exit-status ".body // \"\"" <<< "${release}")"

        if [ -z "${version}" ] || [ "${version}" = "null" ]; then
            >&2 echo "[E] Release without tag_name detected. Aborting."
            rm -f "${releases_json}"
            exit 1
        fi

        if [ "${MODE}" = "--current" ] && ! release_matches_current_versions "${version}" "${current_versions[@]}"; then
            continue
        fi

        if ! require_non_empty_release_body "${release_body}"; then
            >&2 echo "[E] Empty release notes for ${version}. Changelog is mandatory."
            exit 1
        fi

        changelog_path="${CHANGELOGS_DIR}/composer_${version}"
        printf "%s\n" "${release_body}" > "${changelog_path}"
        written=$((written + 1))
        echo "[I] Wrote ${changelog_path}"
    done < <(jq -c '.[] | select(.draft | not)' "${releases_json}")

    rm -f "${releases_json}"
    page=$((page + 1))
done

if [ "${MODE}" = "--current" ] && [ "${written}" -ne 3 ]; then
    >&2 echo "[E] Expected exactly 3 changelog files for current channels, got ${written}."
    exit 1
fi

echo "[I] Backfill complete. Wrote ${written} changelog files (${MODE})."
