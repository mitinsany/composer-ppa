A PPA (unofficial) repository for Composer (Dependency Management for PHP. See https://getcomposer.org/). Contains only loader for binary file, without dependencies.

# Usage

## For stable latest 2.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-latest.list https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-latest.list
sudo apt update
sudo apt install composer
```
## For stable (LTS) 2.2.\* versions


```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-stable.list https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-stable.list
sudo apt update
sudo apt install composer
```
## For old 1.\*.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-v1.list https://mitinsany.github.io/composer-ppa/sources.list.d/composer-ppa-v1.list
sudo apt update
sudo apt install composer
```

## Install via deb822 (.sources) (recommended)

Legacy `.list` format above is kept for compatibility, but `deb822` `.sources` is recommended for new setups.
If Ubuntu repository has a higher package revision (for example `2.9.5-1` vs `2.9.5`), `apt install composer`
may select Ubuntu package. To force this repository package, install an explicit version, for example:
`sudo apt install composer=2.9.5`.

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

## Changelog in Linux Mint / APT

The repository publishes changelog files in:

`changelogs/main/c/composer/composer_<version>`

`Release` metadata includes the `Changelogs` field, so clients can fetch notes before installation.

Check from CLI:

```bash
apt changelog composer
```

## Backfill Changelogs

Daily auto-update (normal operation):

```bash
./scripts/update-packages.sh
```

Bootstrap / one-shot recovery for all upstream Composer releases:

```bash
./scripts/backfill-changelogs.sh --all
```

Service mode: regenerate changelogs only for current `latest`, `stable`, and `v1` versions:

```bash
./scripts/backfill-changelogs.sh --current
```

Manual metadata recovery and signing (`Release`/`InRelease`):

```bash
./scripts/update-release-changelogs.sh
```

GitHub API calls are made via GitHub CLI (`gh`). In CI, use `GH_TOKEN` (workflow sets it from `github.token`).

Note: `reprepro` may print `Unknown header 'Changelogs'` while reading `conf/distributions`.
This warning is expected in this setup and is handled by using `--ignore=unknownfield`
plus explicit `Release`/`InRelease` changelog injection and signing.

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
