#!/usr/bin/env bash
# Fresh release uses a dedicated branch. No push to main, merge, or Pages activation.
set -euo pipefail
umask 077
usage(){ echo "Usage: bash deploy-to-github.sh BUNDLE SHA256 [--push]" >&2; exit 2; }
(( $# == 2 || $# == 3 )) || usage
[[ $# == 2 || $3 == --push ]] || usage
[[ -f $1 && $2 =~ ^[0-9a-f]{64}$ ]] || usage
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cp -- "$1" "$work/release.bundle"
(cd "$work" && printf '%s  release.bundle\n' "$2" | sha256sum -c -)
git init -q --bare "$work/check.git"
repo=(git --git-dir="$work/check.git")
branch=refs/heads/release/v2.1.3-tsp-audited
"${repo[@]}" bundle verify "$work/release.bundle"
"${repo[@]}" fetch --no-tags "$work/release.bundle" "$branch:$branch"
"${repo[@]}" fsck --full --strict
dest=https://github.com/zoeeric2/C4Pay.git
"${repo[@]}" push --dry-run "$dest" "$branch:$branch"
if [[ ${3:-} == --push ]]; then
    "${repo[@]}" push "$dest" "$branch:$branch"
fi
