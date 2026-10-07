#!/usr/bin/env bash
# Generates one Zola content page per <prefix>/<provider>/<module>/vX.Y.Z git
# tag, where <prefix> is one of the known live tag prefixes (currently
# "modules" and "templates/terraform" — see ADR-0110). Each page is a static
# "redirect" page carrying a <meta name="terraform-get"> tag so
# `terraform init` can resolve a short pigeon.dev module source URL to
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
CONTENT_DIR="$REPO_ROOT/workloads/pigeon.dev/src/content/modules"
THEME_CONTENT_DIR="$REPO_ROOT/workloads/pigeon.dev/src/content/theme-versions"

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

# Also generate one *visible* overview page per module (not per version),
# alongside the hidden per-version redirect pages above — same directory, no
# naming collision since these are named "<provider>-<module>.md" with no
# "-vX.Y.Z" suffix. Each overview page carries a usage example extracted from
# the module's own README.md ("## Usage" fenced ```hcl block, verbatim — not
# rewritten to the latest version) when the README has one, and omits it
# otherwise (ADR-0141: shows what the README has today, no backfilling and
# no synthesized fallback).
toml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

module_pairs="$(git -C "$REPO_ROOT" tag --list 'modules/*/*/v*' 'templates/terraform/*/*/v*' \
  | grep -E '^(modules|templates/terraform)/[a-z0-9-]+/[a-z0-9-]+/v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sed -E 's#^(modules|templates/terraform)/([a-z0-9-]+)/([a-z0-9-]+)/v.*#\2/\3#' \
  | sort -u)"

overview_count=0
while IFS= read -r pair; do
  [ -z "$pair" ] && continue
  provider="${pair%%/*}"
  module="${pair##*/}"

  versions="$(git -C "$REPO_ROOT" tag --list "modules/${provider}/${module}/v*" "templates/terraform/${provider}/${module}/v*" \
    | sed -E 's#.*/v([0-9]+\.[0-9]+\.[0-9]+)$#\1#' \
    | sort -t. -k1,1n -k2,2n -k3,3n -u)"
  latest_version="$(echo "$versions" | tail -1)"

  readme="$REPO_ROOT/templates/terraform/${provider}/${module}/README.md"
  description=""
  usage_example=""
  if [ -f "$readme" ]; then
    description="$(awk '
      /^# / && !started { started = 1; next }
      started && /^## / { exit }
      started && /^<!-- BEGIN_TF_DOCS/ { exit }
      started { print }
    ' "$readme" | sed '/^$/d' | tr '\n' ' ' | sed -E 's/ +/ /g; s/^ //; s/ $//')"

    usage_example="$(awk '
      /^## Usage/ { in_usage = 1; next }
      in_usage && /^<!-- BEGIN_TF_DOCS/ { exit }
      in_usage && /^```hcl/ { in_block = 1; next }
      in_usage && in_block && /^```/ { exit }
      in_usage && in_block { print }
    ' "$readme")"
  fi

  slug="${provider}-${module}"
  github_url="https://github.com/noisypigeon/noisypigeon/tree/main/templates/terraform/${provider}/${module}"

  {
    echo "+++"
    echo "title = \"${provider}/${module}\""
    echo "description = \"$(toml_escape "$description")\""
    echo "template = \"module.html\""
    echo "in_search_index = true"
    echo
    echo "[extra]"
    echo "kind = \"module\""
    echo "provider = \"${provider}\""
    echo "module = \"${module}\""
    echo "latest_version = \"${latest_version}\""
    echo "github_url = \"${github_url}\""
    if [ -n "$usage_example" ]; then
      printf 'usage_example = """\n%s\n"""\n' "$usage_example"
    else
      echo 'usage_example = ""'
    fi
    printf 'versions = ['
    first=1
    while IFS= read -r v; do
      [ -z "$v" ] && continue
      [ "$first" -eq 0 ] && printf ', '
      printf '{ version = "%s", path = "modules/%s/%s/v%s" }' "$v" "$provider" "$module" "$v"
      first=0
    done <<<"$versions"
    printf ']\n'
    echo "+++"
  } >"$CONTENT_DIR/${slug}.md"

  overview_count=$((overview_count + 1))
done <<<"$module_pairs"

echo "Generated ${overview_count} module overview page(s) under ${CONTENT_DIR#"$REPO_ROOT"/}."

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
