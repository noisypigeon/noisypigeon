#!/usr/bin/env bash
# Scaffold a new ADR in noisypigeon/pigeon.dev's adr/infrastructure/, which is
# where this project's ADRs live since ADR-0157. Computes the next number,
# writes the skeleton, and puts it on a fresh branch -- then stops, and prints
# the commands to commit and open the PR.
#
# It deliberately does not commit: writing the ADR is the actual work, and an
# auto-commit would only have to be amended afterwards.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADR_DIR_REL="adr/infrastructure"

usage() {
  cat <<'USAGE'
Usage: adr-new.sh --title "a short imperative title" [--author NAME]

  --title    ADR title, used for both the heading and the filename slug.
  --author   Override the author line (default: Willow Finch/Graysen).

Writes adr/infrastructure/NNNN-<slug>.md in the pigeon.dev clone and leaves it
on a new branch. Set ADR_SRC to use your own checkout of that repo.
USAGE
}

title=""
author="Willow Finch/Graysen ([@noisypigeon](https://github.com/noisypigeon))"

while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="$2"; shift 2 ;;
    --author) author="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ -z "$title" ]; then
  echo "--title is required." >&2
  usage >&2
  exit 1
fi

adr_src="$("$SCRIPT_DIR/fetch-adrs.sh")"
adr_dir="$adr_src/$ADR_DIR_REL"

# Next number = max existing + 1, read from origin/HEAD rather than from the
# working tree. The working tree is the wrong source: this script leaves the
# clone on a feature branch, so the next invocation would scan that branch
# (or any other stale checkout) instead of what is actually on main.
# Numbers are never reused or renumbered (ADR-0157); 0136 and 0138 are each
# already used twice, from parallel branches, so this is a max, not a count.
last=0
while read -r name; do
  [ -n "$name" ] || continue
  n="${name%%-*}"
  # Base-10 explicitly: a leading zero would otherwise be read as octal.
  case "$n" in
    [0-9][0-9][0-9][0-9]) if [ "$((10#$n))" -gt "$last" ]; then last="$((10#$n))"; fi ;;
  esac
done < <(git -C "$adr_src" ls-tree --name-only "origin/HEAD:$ADR_DIR_REL" 2>/dev/null || true)
if [ "$last" -eq 0 ]; then
  echo "Warning: no existing ADRs found in $adr_dir." >&2
  echo "If the ADR-0157 move has not been seeded yet, numbering will restart" >&2
  echo "at 0001 and collide with the real corpus. Seed first." >&2
fi
number="$(printf '%04d' "$((last + 1))")"

# -E, not basic regex: BSD/macOS sed does not support \+ here.
slug="$(printf '%s' "$title" |
  tr '[:upper:]' '[:lower:]' |
  sed -E -e 's/[^a-z0-9]+/-/g' -e 's/^-+//' -e 's/-+$//')"

branch="adr/$number-$slug"
file="$adr_dir/$number-$slug.md"

if [ -e "$file" ]; then
  echo "Already exists: $file" >&2
  exit 1
fi

git -C "$adr_src" checkout --quiet -b "$branch" origin/HEAD
mkdir -p "$adr_dir"

cat > "$file" <<ADR
# ADR-$number: $title

- **Author**: $author.
- **Date**: $(date +%Y-%m-%d).
- **Status**: Accepted.

## Context

## Decision

## Consequences

## Out of scope
ADR

echo
echo "Created $file"
echo "  on branch $branch in $adr_src"
echo
echo "Write it, then:"
echo "  git -C \"$adr_src\" add \"$ADR_DIR_REL/$number-$slug.md\""
echo "  git -C \"$adr_src\" commit -m 'docs(adr-$number): $title'"
echo "  git -C \"$adr_src\" push -u origin \"$branch\""
echo "  gh pr create -R noisypigeon/pigeon.dev --fill"
