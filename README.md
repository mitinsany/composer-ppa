A PPA repository for Composer (Dependency Management for PHP. See https://getcomposer.org/). Contains only loader for binary file, without dependencies.

# Usage

## For stable latest 2.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/deb/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-stable.list https://mitinsany.github.io/composer-ppa/deb/composer-ppa-stable.list
sudo apt update
sudo apt install composer-php
```
## For stable (LTS) 2.2.\* versions


```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/deb/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-lts.list https://mitinsany.github.io/composer-ppa/deb/composer-ppa-lts.list
sudo apt update
sudo apt install composer-php
```
## For old 1.\*.\* versions

```bash
sudo curl -SsL -o /usr/share/keyrings/composer-ppa.gpg https://mitinsany.github.io/composer-ppa/deb/composer-ppa.gpg
sudo curl -SsL -o /etc/apt/sources.list.d/composer-ppa-v1.list https://mitinsany.github.io/composer-ppa/deb/composer-ppa-v1.list
sudo apt update
sudo apt install composer-php
```
# Sources

- https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html
- https://makandracards.com/makandra/37763-gpg-extract-private-key-and-import-on-different-machine
- http://blog.jonliv.es/blog/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/
- https://medium.com/sqooba/create-your-own-custom-and-authenticated-apt-repository-1e4a4cf0b864
- https://github.com/tagplus5/vscode-ppa