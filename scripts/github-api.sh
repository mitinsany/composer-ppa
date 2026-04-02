#!/usr/bin/env bash

set -euo pipefail

GITHUB_OWNER_REPO="${GITHUB_OWNER_REPO:-composer/composer}"

ensure_gh_available() {
    if ! command -v gh >/dev/null 2>&1; then
        >&2 echo "[E] GitHub CLI (gh) is required but not installed."
        return 1
    fi
}

ensure_gh_auth() {
    if [ -n "${GH_TOKEN:-}" ]; then
        return 0
    fi
    if gh auth status >/dev/null 2>&1; then
        return 0
    fi
    >&2 echo "[E] GitHub CLI is not authenticated. Set GH_TOKEN or run 'gh auth login'."
    return 1
}

github_releases_page_json() {
    local page="$1"
    ensure_gh_available || return 1
    ensure_gh_auth || return 1

    local output
    if ! output="$(gh api "repos/${GITHUB_OWNER_REPO}/releases" -f per_page=100 -f page="${page}" 2>&1)"; then
        >&2 echo "[E] Failed to fetch GitHub releases page ${page}: ${output}"
        return 1
    fi

    if ! jq -e 'type == "array"' >/dev/null 2>&1 <<< "${output}"; then
        >&2 echo "[E] GitHub API response is not a JSON array for page ${page}."
        return 1
    fi

    printf "%s\n" "${output}"
}
