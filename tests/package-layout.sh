#!/usr/bin/env bash

set -euo pipefail

common_dir="packages/composer-common"
postinstall_template="${common_dir}/postinstall.in"

for channel in latest stable v1; do
    package_dir="packages/${channel}/composer"
    package_json="${package_dir}/package.json"

    jq -e '
        (.version | test("^[0-9]+(\\.[0-9]+)+-[0-9]+$")) and
        (.upstream_version | test("^[0-9]+(\\.[0-9]+)+$")) and
        (.download_url | startswith("https://github.com/composer/composer/releases/download/")) and
        (.download_sha256 | test("^[0-9a-f]{64}$"))
    ' "${package_json}" >/dev/null

    test ! -e "${package_dir}/preinstall"
    test ! -e "${package_dir}/postinstall"
    test ! -e "${package_dir}/postremove"
done

rg -q 'sha256sum --check --status' "${postinstall_template}"
rg -q -- '--retry 3 --connect-timeout 15' "${postinstall_template}"
! rg -q -- '--retry-all-errors' "${postinstall_template}"
rg -q 'mktemp "\$\{install_dir\}/.composer-install' "${postinstall_template}"
rg -q 'mv "\$\{staged_binary\}" "\$\{target_binary\}"' "${postinstall_template}"

test -f "${common_dir}/postremove"
rg -q 'remove\|purge' "${common_dir}/postremove"
