#!/usr/bin/env bash

set -euo pipefail

CHANNELS=(latest stable v1)

echo "[I] Running shell syntax validation..."
bash -n update-packages.sh scripts/*.sh

for channel in "${CHANNELS[@]}"; do
    release_file="deb/dists/${channel}/Release"
    inrelease_file="deb/dists/${channel}/InRelease"
    package_json="packages/${channel}/composer/package.json"

    if ! rg -q '^Changelogs:' "${release_file}"; then
        >&2 echo "[E] Missing Changelogs header in ${release_file}"
        exit 1
    fi
    if ! rg -q '^Changelogs:' "${inrelease_file}"; then
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
