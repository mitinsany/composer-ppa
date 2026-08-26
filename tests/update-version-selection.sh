#!/usr/bin/env bash

set -euo pipefail

source scripts/update-packages.sh

package_file="$(mktemp)"
trap 'rm -f "${package_file}"' EXIT
valid_sha256="$(printf 'a%.0s' {1..64})"

package_needs_update '2.10.2' '2.10.2-1' '' "${package_file}"

if package_needs_update '2.10.2-1' '2.10.1-1' "${valid_sha256}" "${package_file}"; then
    echo 'An older upstream release must never replace the current package.' >&2
    exit 1
fi

if package_needs_update '2.10.2-1' '2.10.2-1' "${valid_sha256}" "${package_file}"; then
    echo 'A complete current package must not be rebuilt.' >&2
    exit 1
fi

unlink "${package_file}"
package_file='missing-package.deb'
package_needs_update '2.10.2-1' '2.10.2-1' "${valid_sha256}" "${package_file}"

