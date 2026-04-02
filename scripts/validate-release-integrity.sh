#!/usr/bin/env bash

set -euo pipefail

CHANNELS=(latest stable v1)

has_pattern() {
    local pattern="$1"
    local file="$2"
    if command -v rg >/dev/null 2>&1; then
        rg -q "${pattern}" "${file}"
    else
        grep -Eq "${pattern}" "${file}"
    fi
}

echo "[I] Running shell syntax validation..."
bash -n update-packages.sh scripts/*.sh

for channel in "${CHANNELS[@]}"; do
    release_file="deb/dists/${channel}/Release"
    inrelease_file="deb/dists/${channel}/InRelease"
    package_json="packages/${channel}/composer/package.json"

    if ! has_pattern '^Changelogs:' "${release_file}"; then
        >&2 echo "[E] Missing Changelogs header in ${release_file}"
        exit 1
    fi
    if ! has_pattern '^Changelogs:' "${inrelease_file}"; then
        >&2 echo "[E] Missing Changelogs header in ${inrelease_file}"
        exit 1
    fi

    version="$(jq --raw-output --exit-status ".version" "${package_json}")"
    changelog_file="changelogs/main/c/composer/composer_${version}"
    if [ ! -s "${changelog_file}" ]; then
        >&2 echo "[E] Missing or empty changelog file: ${changelog_file}"
        exit 1
    fi
done

echo "[I] Release integrity validation passed."
