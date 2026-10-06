#!/usr/bin/env bash
# Generates one Zola content page per <prefix>/<provider>/<module>/vX.Y.Z git
# tag, where <prefix> is one of the known live tag prefixes (currently
# "modules" and "templates/terraform" — see ADR-0110). Each page is a static
# "redirect" page carrying a <meta name="terraform-get"> tag so
# `terraform init` can resolve a short noisypigeon.com module source URL to
# this repo's tagged git:: source. The public URL always uses "modules/..."
# regardless of which prefix the tag actually lives under, so the public
# namespace stays stable even as the repo's internal layout moves.
# See docs/adr/0109, docs/adr/0110.
#
# Also generates one page per templates/zola-site/vX.Y.Z git tag (ADR-0114) —
# a separate loop since the tag shape doesn't fit the provider/module pattern
# above (zola-site is one flat unit, not a provider+module pair). Unlike the
# terraform pages, there is no fetch-by-URL protocol for Zola themes, so
# these pages are a human-facing redirect to the GitHub release page only,
# not a build input.
#
# Regenerate-all semantics: every run wipes and rewrites every generated
# page under content/modules/ and content/theme-versions/ (except each
# directory's hand-authored _index.md) from the current set of tags. Safe to
# run repeatedly; fully idempotent.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CONTENT_DIR="$REPO_ROOT/workloads/noisypigeon.com/src/content/modules"
THEME_CONTENT_DIR="$REPO_ROOT/workloads/noisypigeon.com/src/content/theme-versions"

mkdir -p "$CONTENT_DIR"

# Wipe only generated pages; keep the hand-authored section marker.
find "$CONTENT_DIR" -maxdepth 1 -name '*.md' ! -name '_index.md' -delete

count=0
while IFS= read -r tag; do
  [ -z "$tag" ] && continue

  # Explicit allowlist, not a generic catch-all: legacy terraform/modules/...
  # tags stay unredirected (ADR-0109's permanent boundary).
  if [[ ! "$tag" =~ ^(modules|templates/terraform)/([a-z0-9-]+)/([a-z0-9-]+)/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "::warning::Skipping tag with unexpected shape: $tag" >&2
    continue
  fi

  prefix="${BASH_REMATCH[1]}"
  provider="${BASH_REMATCH[2]}"
  module="${BASH_REMATCH[3]}"
  version="${BASH_REMATCH[4]}"

  slug="${provider}-${module}-v${version}"
  full_tag="${prefix}/${provider}/${module}/v${version}"
  # The public URL stays "modules/..." forever, independent of which prefix
  # the tag actually lives under (see ADR-0110) — this is the whole point.
  url_path="modules/${provider}/${module}/v${version}"
  git_source="git::https://github.com/noisypigeon/noisypigeon.git//${prefix}/${provider}/${module}?ref=${full_tag}"
  github_url="https://github.com/noisypigeon/noisypigeon/releases/tag/${full_tag}"

  cat > "$CONTENT_DIR/${slug}.md" <<EOF
+++
title = "${provider}/${module} v${version}"
description = "Terraform module source redirect for modules/${provider}/${module} v${version}."
path = "${url_path}"
template = "module-redirect.html"
in_search_index = false
include_in_feeds = false
hidden = true

[extra]
git_source = "${git_source}"
github_url = "${github_url}"
+++
EOF

  count=$((count + 1))
done < <(git -C "$REPO_ROOT" tag --list 'modules/*/*/v*' 'templates/terraform/*/*/v*' | sort)

echo "Generated ${count} module redirect page(s) under ${CONTENT_DIR#"$REPO_ROOT"/}."

mkdir -p "$THEME_CONTENT_DIR"
find "$THEME_CONTENT_DIR" -maxdepth 1 -name '*.md' ! -name '_index.md' -delete

theme_count=0
while IFS= read -r tag; do
  [ -z "$tag" ] && continue

  if [[ ! "$tag" =~ ^templates/(zola-site)/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "::warning::Skipping theme tag with unexpected shape: $tag" >&2
    continue
  fi

  theme="${BASH_REMATCH[1]}"
  version="${BASH_REMATCH[2]}"

  slug="${theme}-v${version}"
  url_path="templates/${theme}/v${version}"
  github_url="https://github.com/noisypigeon/noisypigeon/releases/tag/${tag}"

  cat > "$THEME_CONTENT_DIR/${slug}.md" <<EOF
+++
title = "templates/${theme} v${version}"
description = "templates/${theme} theme, version ${version}."
path = "${url_path}"
template = "theme-redirect.html"
in_search_index = false
include_in_feeds = false
hidden = true

[extra]
github_url = "${github_url}"
+++
EOF

  theme_count=$((theme_count + 1))
done < <(git -C "$REPO_ROOT" tag --list 'templates/zola-site/v*' | sort)

echo "Generated ${theme_count} theme-version redirect page(s) under ${THEME_CONTENT_DIR#"$REPO_ROOT"/}."
