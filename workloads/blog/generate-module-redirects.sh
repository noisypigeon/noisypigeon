#!/usr/bin/env bash
# Generates one Zola content page per modules/<provider>/<module>/vX.Y.Z git
# tag. Each page is a static "redirect" page carrying a
# <meta name="terraform-get"> tag so `terraform init` can resolve a short
# noisypigeon.com module source URL to this repo's tagged git:: source.
# See docs/adr/0109.
#
# Regenerate-all semantics: every run wipes and rewrites every generated
# page under content/modules/ (except the hand-authored _index.md) from the
# current set of tags. Safe to run repeatedly; fully idempotent.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CONTENT_DIR="$REPO_ROOT/workloads/blog/src/content/modules"

mkdir -p "$CONTENT_DIR"

# Wipe only generated pages; keep the hand-authored section marker.
find "$CONTENT_DIR" -maxdepth 1 -name '*.md' ! -name '_index.md' -delete

count=0
while IFS= read -r tag; do
  [ -z "$tag" ] && continue

  if [[ ! "$tag" =~ ^modules/([a-z0-9-]+)/([a-z0-9-]+)/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "::warning::Skipping tag with unexpected shape: $tag" >&2
    continue
  fi

  provider="${BASH_REMATCH[1]}"
  module="${BASH_REMATCH[2]}"
  version="${BASH_REMATCH[3]}"

  slug="${provider}-${module}-v${version}"
  url_path="modules/${provider}/${module}/v${version}"
  git_source="git::https://github.com/noisypigeon/noisypigeon.git//modules/${provider}/${module}?ref=modules/${provider}/${module}/v${version}"
  github_url="https://github.com/noisypigeon/noisypigeon/releases/tag/modules/${provider}/${module}/v${version}"

  cat > "$CONTENT_DIR/${slug}.md" <<EOF
+++
title = "${provider}/${module} v${version}"
description = "Terraform module source redirect for modules/${provider}/${module} v${version}."
path = "${url_path}"
template = "module-redirect.html"
in_search_index = false
include_in_feeds = false

[extra]
git_source = "${git_source}"
github_url = "${github_url}"
+++
EOF

  count=$((count + 1))
done < <(git -C "$REPO_ROOT" tag --list 'modules/*/*/v*' | sort)

echo "Generated ${count} module redirect page(s) under ${CONTENT_DIR#"$REPO_ROOT"/}."
