# AGENTS.md

## Purpose

This repository hosts an unofficial APT repository for Composer packages, built and published via `reprepro`.
Main flows:
- track Composer releases from GitHub;
- rebuild `.deb` wrappers with `fpm`;
- publish metadata and package indexes under `deb/` and `db/`.

## Project Map

- `scripts/update-packages.sh`: main automation entrypoint; fetches releases, updates package templates, builds and includes `.deb` into the repo.
- `scripts/build-single-deb.sh`: builds one Debian package from a package template folder.
- `packages/<channel>/composer/`: package templates (`package.json`, install/remove scripts).
- `conf/`: `reprepro` configuration (`distributions`, `options`).
- `deb/`: published APT repository contents (indexes, pool, signatures).
- `db/`: `reprepro` database files.
- `changelogs/`: published changelog files used by APT/Mint changelog fetch.
- `scripts/docker/`: helper scripts to prepare CI/runtime dependencies and import signing key.
- `scripts/backfill-changelogs.sh`: regenerates changelogs (`--current` for current channels, `--all` for all Composer releases).
- `scripts/github-api.sh`: shared GitHub API helper (uses GitHub CLI `gh`).
- `scripts/update-release-changelogs.sh`: injects `Changelogs` into `Release` and resigns `Release.gpg` / `InRelease`.
- `scripts/validate-release-integrity.sh`: validates release metadata/changelog integrity before commit.
- `.github/workflows/build.yml`: scheduled/manual CI update + auto-commit pipeline.

## Working Rules For Agents

1. Keep changes minimal and task-focused.
2. Never manually edit generated repository indexes in `deb/dists/**` or `db/**` unless the task explicitly requires low-level recovery.
3. Prefer modifying source-of-truth files:
   - `packages/**`
   - `conf/**`
   - automation scripts (`scripts/update-packages.sh`, `scripts/build-single-deb.sh`, `scripts/**`)
4. Preserve existing package channels and their intent:
   - `latest`: `2.*.*`
   - `stable`: `2.2.*`
   - `v1`: `1.*.*`
5. Do not remove or rotate signing configuration (`SignWith`, key files) unless explicitly requested.
6. If task touches library/framework usage, use MCP `context7` for documentation lookup when needed.
7. Local package build/update workflow should run inside Docker container built from `docker/Dockerfile`.
8. Changelog text is mandatory for package updates. Do not publish versions with empty release notes.
9. Warning `Unknown header 'Changelogs'` from `reprepro` is expected; treat as non-fatal when using `--ignore=unknownfield` plus `scripts/update-release-changelogs.sh`.

## Standard Local Workflow

1. Install required tools (or use `scripts/docker/install-dependencies.sh`):
   - `jq`, `gh`, `curl`, `reprepro`, `gpg`, `ruby` + `fpm`, `dpkg`, `ripgrep` (optional; validation script has grep fallback).
2. Ensure signing key is imported (CI uses `scripts/docker/decrypt.sh` with `ENCRYPTED_KEY` and `ENCRYPTED_IV`).
   - for CI GitHub API access, set `GH_TOKEN` (workflow uses `${{ github.token }}`).
3. Run update pipeline:
   - `./scripts/update-packages.sh`
   - this is the default daily mode and performs targeted changelog updates only for changed versions
4. Inspect resulting changes:
   - `git status`
   - verify updated versions in `packages/*/composer/package.json`
   - run `./scripts/backfill-changelogs.sh --all` only for bootstrap/one-shot recovery
   - run `./scripts/backfill-changelogs.sh --current` as service check for current channel versions
   - run `./scripts/update-release-changelogs.sh` after metadata changes
   - run `./scripts/validate-release-integrity.sh`
   - verify changelog files in `changelogs/main/c/composer/`
   - verify `deb/` and `db/` updates were produced.

## Recommended Docker Workflow (Local)

Use this as the default local way to run package updates/build:

```bash
docker build -f docker/Dockerfile -t composer-ppa-builder .
docker run --rm -it -v "$PWD:/app" composer-ppa-builder bash -lc "./scripts/update-packages.sh"
```

## Validation Checklist Before Commit

- Scripts still pass shell syntax checks:
  - `bash -n scripts/update-packages.sh scripts/build-single-deb.sh scripts/docker/*.sh`
- No accidental edits outside task scope.
- If versions changed:
  - matching `preinstall` download URLs are updated;
  - changelog file exists at `changelogs/main/c/composer/composer_<version>`;
  - corresponding files in `deb/pool/main/c/composer/` exist;
  - repo metadata files under `deb/dists/<channel>/` changed consistently.
- Commit message should clearly state channel/version upgrades.

## Notes On Safety

- `scripts/update-packages.sh` rewrites package templates and repo state; run from repository root.
- Packaging scripts operate on `/tmp` and may overwrite temp files with fixed names.
- Package install scripts write to `/usr/local/bin` in target systems; be careful when changing install/remove logic.
