#!/usr/bin/env bash

set -euxo pipefail

openssl aes-256-cbc \
    -K "$ENCRYPTED_KEY" \
    -iv "$ENCRYPTED_IV" \
    -in 0xCF6EC707.asc.enc \
    -out 0xCF6EC707.asc -d

gpg --no-tty --import 0xCF6EC707.asc
