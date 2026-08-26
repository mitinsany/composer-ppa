#!/usr/bin/env bash

set -euo pipefail

script='scripts/update-packages.sh'

rg -q '^set -euo pipefail$' "${script}"
rg -q '^DEBIAN_REVISION="[0-9]+"$' "${script}"
rg -q -- '--retry 3 --retry-all-errors --connect-timeout 15' "${script}"
rg -q 'sha256sum' "${script}"
rg -q 'assets\[\].*name.*composer\.phar' "${script}"

if rg -qi 'Content-Length|content_length|assets\[0\]' "${script}"; then
    echo 'The updater must not rely on Content-Length or GitHub asset ordering.' >&2
    exit 1
fi

