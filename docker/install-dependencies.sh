#!/usr/bin/env bash

set -euxo pipefail

apt-get update
# DEBIAN_FRONTEND=noninteractive apt-get -qq --yes upgrade
DEBIAN_FRONTEND=noninteractive apt-get -qq install --yes --no-install-recommends \
  curl \
  binutils \
  git \
  dpkg-dev \
  apt-utils \
  gnupg2 \
  jq \
  ruby \
  sed

gem install fpm
