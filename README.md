A PPA (unofficial) repository for Composer (Dependency Management for PHP. See https://getcomposer.org/). Contains only loader for binary file, without dependencies.

[![Build & Publish](https://github.com/mitinsany/composer-ppa/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/mitinsany/composer-ppa/actions/workflows/build.yml)
[![Latest package](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmitinsany%2Fcomposer-ppa%2Fmain%2Fpackages%2Flatest%2Fcomposer%2Fpackage.json&query=%24.version&label=latest)](https://github.com/mitinsany/composer-ppa/tree/main/packages/latest/composer)
[![Stable package](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmitinsany%2Fcomposer-ppa%2Fmain%2Fpackages%2Fstable%2Fcomposer%2Fpackage.json&query=%24.version&label=stable)](https://github.com/mitinsany/composer-ppa/tree/main/packages/stable/composer)
[![V1 package](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmitinsany%2Fcomposer-ppa%2Fmain%2Fpackages%2Fv1%2Fcomposer%2Fpackage.json&query=%24.version&label=v1)](https://github.com/mitinsany/composer-ppa/tree/main/packages/v1/composer)

# Usage

## Install via deb822 (.sources)
If the Ubuntu repository has a higher package version, `apt install composer` may select the Ubuntu package.
Use `apt-cache policy composer` to find this repository's current version and install it explicitly with
`sudo apt install composer=<version>`.

### For stable latest 2.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-latest.sources https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-latest.sources
sudo apt update
sudo apt install composer
```

### For stable (LTS) 2.2.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-stable.sources https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-stable.sources
sudo apt update
sudo apt install composer
```

### For old 1.\*.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-v1.sources https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-v1.sources
sudo apt update
sudo apt install composer
```

# Sources

- https://unixforum.org/viewtopic.php?t=79513
- https://wikitech.wikimedia.org/wiki/Reprepro
- https://blog.packagecloud.io/how-to-create-debian-repository-with-reprepro/
- https://earthly.dev/blog/creating-and-hosting-your-own-deb-packages-and-apt-repo/
- https://scotbofh.wordpress.com/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/
- https://sites.google.com/view/chewkeanho/guides/linux-os/reprepro/setup?authuser=0
- https://wiki.debian.org/DebianRepository/SetupWithReprepro#Configuring_reprepro
- https://salsa.debian.org/brlink/reprepro/blob/debian/docs/manual.html
- https://wikitech.wikimedia.org/wiki/Reprepro#External_links
- https://habr.com/ru/articles/50540/
- https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html
- https://makandracards.com/makandra/37763-gpg-extract-private-key-and-import-on-different-machine
- http://blog.jonliv.es/blog/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/
- https://medium.com/sqooba/create-your-own-custom-and-authenticated-apt-repository-1e4a4cf0b864
- https://www.linuxbabe.com/linux-server/set-up-package-repository-debian-ubuntu-server
- https://github.com/tagplus5/vscode-ppa
