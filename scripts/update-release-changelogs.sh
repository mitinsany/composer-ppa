#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_BASE="${ROOT_DIR}/deb/dists"
CHANGELOGS_URL="https://mitinsany.github.io/composer-ppa/changelogs/@CHANGEPATH@"
SIGNING_KEY="610BDB5BCF6EC707"
CHANNELS=(latest stable v1)

inject_changelogs_header() {
    local release_file="$1"
    local tmp_file
    tmp_file="$(mktemp)"

    awk -v changelogs_url="${CHANGELOGS_URL}" '
        BEGIN { injected=0 }
        /^Changelogs:/ { next }
        {
            print
            if (!injected && /^Components:/) {
                print "Changelogs: " changelogs_url
                injected=1
            }
        }
        END {
            if (!injected) {
                print "Changelogs: " changelogs_url
            }
        }
    ' "${release_file}" > "${tmp_file}"

    mv "${tmp_file}" "${release_file}"
}

if ! gpg --list-secret-keys --keyid-format LONG "${SIGNING_KEY}" >/dev/null 2>&1; then
    >&2 echo "[E] Signing key ${SIGNING_KEY} is not available in the current GPG keyring."
    exit 1
fi

for channel in "${CHANNELS[@]}"; do
    release_dir="${RELEASE_BASE}/${channel}"
    release_file="${release_dir}/Release"
    inrelease_file="${release_dir}/InRelease"
    release_gpg_file="${release_dir}/Release.gpg"

    if [ ! -f "${release_file}" ]; then
        >&2 echo "[E] Cannot find ${release_file}"
        exit 1
    fi

    inject_changelogs_header "${release_file}"

    gpg --batch --yes --local-user "${SIGNING_KEY}" --detach-sign --output "${release_gpg_file}" "${release_file}"
    gpg --batch --yes --local-user "${SIGNING_KEY}" --clearsign --output "${inrelease_file}" "${release_file}"

    echo "[I] Updated and signed ${channel}/Release with Changelogs field."
done
