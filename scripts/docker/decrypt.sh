#!/usr/bin/env bash

set -euo pipefail

KEY_FILE="${COMPOSER_PPA_KEY_FILE:-0xCF6EC707.asc.enc}"
OUT_FILE="${KEY_FILE%.enc}"
trap 'rm -f "${OUT_FILE}"' EXIT

openssl aes-256-cbc \
    -K "$ENCRYPTED_KEY" \
    -iv "$ENCRYPTED_IV" \
    -in "${KEY_FILE}" \
    -out "${OUT_FILE}" -d

gpg --import "${OUT_FILE}"
