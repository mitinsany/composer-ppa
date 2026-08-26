#!/usr/bin/env bash

set -euo pipefail

workflow='.github/workflows/build.yml'
decrypt_script='scripts/docker/decrypt.sh'

rg -q '^concurrency:$' "${workflow}"
rg -q 'ENCRYPTED_KEY: \$\{\{ secrets\.ENCRYPTED_KEY \}\}' "${workflow}"
rg -q 'ENCRYPTED_IV: \$\{\{ secrets\.ENCRYPTED_IV \}\}' "${workflow}"
if rg -q '^        env:$' "${workflow}"; then
    echo 'Repository signing secrets must not be job-wide environment variables.' >&2
    exit 1
fi

rg -q '^set -euo pipefail$' "${decrypt_script}"
if rg -q '^set -.*x' "${decrypt_script}"; then
    echo 'Key decryption must not enable shell command tracing.' >&2
    exit 1
fi
rg -q "trap 'rm -f" "${decrypt_script}"

