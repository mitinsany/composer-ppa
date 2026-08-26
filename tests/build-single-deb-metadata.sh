#!/usr/bin/env bash

set -euo pipefail

builder='scripts/build-single-deb.sh'
updater='scripts/update-packages.sh'

rg -q -- '--depends "curl"' "${builder}"
if rg -q -- '--deb-pre-depends|--deb-installed-size' "${builder}"; then
    echo 'Composer runtime tools must be regular dependencies and Installed-Size must be calculated by fpm.' >&2
    exit 1
fi

rg -q 'deb_file="/tmp/composer_\$\{remote_package_version\}_amd64.deb"' "${updater}"
if rg -q 'ls -c /tmp/\*\.deb' "${updater}"; then
    echo 'The updater must not select an arbitrary package from /tmp.' >&2
    exit 1
fi

