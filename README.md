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
