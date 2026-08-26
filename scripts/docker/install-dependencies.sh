#!/usr/bin/env bash

set -euxo pipefail

apt-get update
# DEBIAN_FRONTEND=noninteractive apt-get -qq --yes upgrade
DEBIAN_FRONTEND=noninteractive apt-get -qq install --yes --no-install-recommends \
  ca-certificates \
  curl \
  binutils \
  git \
  gh \
  reprepro \
  gnupg2 \
  jq \
  openssl \
  ripgrep \
  ruby \
  sed

gem install fpm
