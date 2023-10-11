#!/usr/bin/env bash

set -euxo pipefail

openssl aes-256-cbc \
    -K "$ENCRYPTED_5D87B9A7_KEY" \
    -iv "$ENCRYPTED_5D87B9A7_IV" \
    -in composer-ppa.gpg.enc \
    -out composer-ppa.gpg -d

gpg --import composer-ppa.gpg
