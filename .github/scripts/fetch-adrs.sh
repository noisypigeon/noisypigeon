#!/usr/bin/env bash
# Maintains a local clone of noisypigeon/pigeon.dev, which holds this
# project's ADRs at adr/infrastructure/ since ADR-0157. Prints the clone's
# path on stdout so callers can locate it.
#
# Deliberately NOT modeled on noisypigeon.com/fetch-templates.sh, which
# does `git reset --hard origin/HEAD` on every run. That is correct there (the
# clone is a disposable read-only build input) and wrong here: an ADR is
# authored in this clone over multiple commands, so a reset would silently
# destroy work in progress. This script refuses to touch a dirty clone
# instead.
#
# Set ADR_SRC to use your own checkout of pigeon.dev and skip all fetching,
# the way fetch-templates.sh honors TEMPLATES_SRC.
set -euo pipefail

ADR_REPO_URL="${ADR_REPO_URL:-https://github.com/noisypigeon/pigeon.dev.git}"

# A caller-supplied checkout is used as-is: never fetched, never reset. Checked
# before anything else, so an explicit ADR_SRC works from outside this repo.
if [ -n "${ADR_SRC:-}" ]; then
  if [ ! -d "$ADR_SRC/.git" ]; then
    echo "ADR_SRC=$ADR_SRC is not a git checkout." >&2
    exit 1
  fi
  echo "$ADR_SRC"
  exit 0
fi

ADR_SRC="$(git rev-parse --show-toplevel)/.adr-src"

if [ ! -d "$ADR_SRC/.git" ]; then
  echo "Cloning $ADR_REPO_URL -> $ADR_SRC" >&2
  git clone --quiet "$ADR_REPO_URL" "$ADR_SRC"
  echo "$ADR_SRC"
  exit 0
fi

# Never reset: bail out rather than discard an in-progress ADR.
if [ -n "$(git -C "$ADR_SRC" status --porcelain)" ]; then
  echo "Refusing to fetch: $ADR_SRC has uncommitted changes." >&2
  echo "Commit, stash, or discard them first: git -C \"$ADR_SRC\" status" >&2
  exit 1
fi

for state in rebase-merge rebase-apply; do
  if [ -d "$(git -C "$ADR_SRC" rev-parse --git-path "$state")" ]; then
    echo "Refusing to fetch: $ADR_SRC is mid-$state." >&2
    exit 1
  fi
done

git -C "$ADR_SRC" fetch --quiet --prune origin
echo "$ADR_SRC"
