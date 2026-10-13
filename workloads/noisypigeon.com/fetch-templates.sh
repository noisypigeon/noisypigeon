#!/usr/bin/env bash
# Materializes the templates repo -- noisypigeon/pigeon.dev, which owns
# templates/terraform/* and templates/zola-site/ since ADR-0154 -- into a
# gitignored /.templates-src/ at this repo's root. Both Zola sites read out of
# it: generate-module-redirects.sh for module tags/READMEs/CHANGELOGs, and
# templates/zola-site/resolve-theme.sh for the theme itself. One clone, two
# consumers, nothing checked in.
#
# Blobless (--filter=blob:none) because the common case only needs the tag
# graph and a handful of files; blobs are fetched on demand when a pinned
# `git archive` actually needs them.
#
# Set TEMPLATES_SRC to point at your own checkout of that repo (e.g. when
# iterating on a module and a consuming site together) and this script leaves
# it completely alone -- it only ever manages the default path.
set -euo pipefail

TEMPLATES_REPO_URL="${TEMPLATES_REPO_URL:-https://github.com/noisypigeon/pigeon.dev.git}"
REPO_ROOT="$(git rev-parse --show-toplevel)"

if [ -n "${TEMPLATES_SRC:-}" ]; then
  if [ ! -d "$TEMPLATES_SRC/templates" ]; then
    echo "::error::TEMPLATES_SRC=$TEMPLATES_SRC has no templates/ directory" >&2
    exit 1
  fi
  echo "Templates resolved -> $TEMPLATES_SRC (caller-supplied, left as-is)"
  exit 0
fi

TEMPLATES_SRC="$REPO_ROOT/.templates-src"

if [ -d "$TEMPLATES_SRC/.git" ]; then
  git -C "$TEMPLATES_SRC" fetch --quiet --tags --prune --force origin
  git -C "$TEMPLATES_SRC" reset --quiet --hard origin/HEAD
else
  rm -rf "$TEMPLATES_SRC"
  git clone --quiet --filter=blob:none "$TEMPLATES_REPO_URL" "$TEMPLATES_SRC"
fi

echo "Templates resolved -> ${TEMPLATES_SRC#"$REPO_ROOT"/} ($(git -C "$TEMPLATES_SRC" rev-parse --short HEAD), $(git -C "$TEMPLATES_SRC" tag | wc -l | tr -d ' ') tags)"
