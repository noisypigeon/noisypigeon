#!/usr/bin/env bash
# Generates one Zola content page per <prefix>/<provider>/<module>/vX.Y.Z git
# tag, where <prefix> is one of the known live tag prefixes (currently
# "modules" and "templates/terraform" — see ADR-0110). Each page is a static
# "redirect" page carrying a <meta name="terraform-get"> tag so
# `terraform init` can resolve a short pigeon.dev module source URL to the
# tagged git:: source. The public URL always uses "modules/..." regardless of
# which prefix the tag actually lives under, so the public namespace stays
# stable even as the repo's internal layout moves.
# See ADR-0109, ADR-0110 (noisypigeon/pigeon.dev, adr/infrastructure/).
#
# Since ADR-0154 the two prefixes live in *different repos*, so a tag's prefix
# also decides which repo its git:: source names:
#
#   modules/...             -> noisypigeon/noisypigeon  (frozen; 20 tags that
#                              predate templates/ existing, so the ADR-0154
#                              filter-repo could not carry them, and one of
#                              them is still live-pinned)
#   templates/terraform/... -> noisypigeon/pigeon.dev   (where templates/ now
#                              lives, and where every future tag is cut)
#
# Also generates one page per templates/zola-site/vX.Y.Z tag (ADR-0114) — a
# separate loop since the tag shape doesn't fit the provider/module pattern
# above (zola-site is one flat unit, not a provider+module pair). Unlike the
# terraform pages, there is no fetch-by-URL protocol for Zola themes, so these
# pages are a human-facing redirect to the GitHub release page only, not a
# build input.
#
# And, since ADR-0154, one post per module release under content/releases/,
# derived from the modules' own CHANGELOG.md files. template-release.yml used
# to write these directly, but it now runs in the other repo and can't reach
# this site's content tree; the changelog entry it writes there is already the
# same text, so the post is derived from it rather than cross-repo written.
#
# Regenerate-all semantics: every run wipes and rewrites every generated page
# under content/modules/, content/theme-versions/ and content/releases/
# (except each directory's hand-authored _index.md) from the current set of
# tags and changelogs. Safe to run repeatedly; fully idempotent.
#
# Reads templates/ out of the clone workloads/pigeon.dev/fetch-templates.sh
# maintains; run that first (both .mise.toml and zola-sites-deploy.yml do).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
TEMPLATES_SRC="${TEMPLATES_SRC:-$REPO_ROOT/.templates-src}"
CONTENT_DIR="$REPO_ROOT/workloads/pigeon.dev/src/content/modules"
THEME_CONTENT_DIR="$REPO_ROOT/workloads/pigeon.dev/src/content/theme-versions"
RELEASES_CONTENT_DIR="$REPO_ROOT/workloads/pigeon.dev/src/content/releases"

if [ ! -d "$TEMPLATES_SRC/templates/terraform" ]; then
  echo "::error::No templates/terraform in $TEMPLATES_SRC — run workloads/pigeon.dev/fetch-templates.sh first" >&2
  exit 1
fi

# A tag prefix names the repo that tag lives in (ADR-0154).
repo_for_prefix() {
  case "$1" in
    modules) echo "noisypigeon/noisypigeon" ;;
    templates/terraform) echo "noisypigeon/pigeon.dev" ;;
    *)
      echo "::error::No repo mapping for tag prefix: $1" >&2
      exit 1
      ;;
  esac
}

# ...and which git dir to ask about it. The legacy modules/* set is frozen in
# this repo; everything under templates/ moved out.
legacy_tags() { git -C "$REPO_ROOT" tag --list "$@"; }
templates_tags() { git -C "$TEMPLATES_SRC" tag --list "$@"; }

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
  repo="$(repo_for_prefix "$prefix")"
  # The public URL stays "modules/..." forever, independent of which prefix
  # the tag actually lives under, or which repo (see ADR-0110, ADR-0154) —
  # this is the whole point.
  url_path="modules/${provider}/${module}/v${version}"
  git_source="git::https://github.com/${repo}.git//${prefix}/${provider}/${module}?ref=${full_tag}"
  github_url="https://github.com/${repo}/releases/tag/${full_tag}"

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
done < <({ legacy_tags 'modules/*/*/v*'; templates_tags 'templates/terraform/*/*/v*'; } | sort)

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

module_pairs="$({ legacy_tags 'modules/*/*/v*'; templates_tags 'templates/terraform/*/*/v*'; } \
  | grep -E '^(modules|templates/terraform)/[a-z0-9-]+/[a-z0-9-]+/v[0-9]+\.[0-9]+\.[0-9]+$' \
  | sed -E 's#^(modules|templates/terraform)/([a-z0-9-]+)/([a-z0-9-]+)/v.*#\2/\3#' \
  | sort -u)"

overview_count=0
while IFS= read -r pair; do
  [ -z "$pair" ] && continue
  provider="${pair%%/*}"
  module="${pair##*/}"

  versions="$({ legacy_tags "modules/${provider}/${module}/v*"; templates_tags "templates/terraform/${provider}/${module}/v*"; } \
    | sed -E 's#.*/v([0-9]+\.[0-9]+\.[0-9]+)$#\1#' \
    | sort -t. -k1,1n -k2,2n -k3,3n -u)"
  latest_version="$(echo "$versions" | tail -1)"

  readme="$TEMPLATES_SRC/templates/terraform/${provider}/${module}/README.md"
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
  github_url="https://github.com/noisypigeon/pigeon.dev/tree/main/templates/terraform/${provider}/${module}"

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
  github_url="https://github.com/noisypigeon/pigeon.dev/releases/tag/${tag}"

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
done < <(templates_tags 'templates/zola-site/v*' | sort)

echo "Generated ${theme_count} theme-version redirect page(s) under ${THEME_CONTENT_DIR#"$REPO_ROOT"/}."

# One post per module release, from the modules' own CHANGELOG.md files
# (ADR-0141's content, ADR-0154's mechanism). Each "## [X.Y.Z] - YYYY-MM-DD"
# entry becomes a post: its "### " line is the description, everything after
# is the body verbatim. Note the split is on the versioned heading
# specifically, not any "## " -- at least one entry body contains its own
# "## Test plan" heading.
mkdir -p "$RELEASES_CONTENT_DIR"
find "$RELEASES_CONTENT_DIR" -maxdepth 1 -name '*.md' ! -name '_index.md' -delete

# Posts carry an America/Los_Angeles timestamp, matching what
# template-release.yml stamps on the day it cuts a release. The offset is
# whatever that date's was, so entries either side of a DST change differ --
# precompute one offset per distinct date (GNU date first, BSD fallback).
offset_for_date() {
  local raw
  raw="$(TZ="America/Los_Angeles" date -d "$1 12:00:00" +%z 2>/dev/null \
    || TZ="America/Los_Angeles" date -j -f "%Y-%m-%d %H:%M:%S" "$1 12:00:00" +%z 2>/dev/null)"
  if [ -z "$raw" ]; then
    echo "::error::Could not compute UTC offset for date $1" >&2
    exit 1
  fi
  echo "$raw" | sed -E 's/([+-][0-9]{2})([0-9]{2})/\1:\2/'
}

changelogs="$(find "$TEMPLATES_SRC/templates/terraform" -mindepth 3 -maxdepth 3 -name CHANGELOG.md | sort)"

offset_map=""
while IFS= read -r d; do
  [ -z "$d" ] && continue
  offset_map="${offset_map}${d}=$(offset_for_date "$d");"
done < <(echo "$changelogs" | xargs grep -hE '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' \
  | sed -E 's/^## \[[0-9.]+\] - ([0-9-]+)$/\1/' | sort -u)

release_count=0
while IFS= read -r changelog; do
  [ -z "$changelog" ] && continue
  module="$(basename "$(dirname "$changelog")")"
  provider="$(basename "$(dirname "$(dirname "$changelog")")")"

  written=$(awk -v provider="$provider" -v module="$module" \
                -v outdir="$RELEASES_CONTENT_DIR" -v offsets="$offset_map" '
    function offset_for(d,   n, i, parts, kv) {
      n = split(offsets, parts, ";")
      for (i = 1; i <= n; i++) {
        if (split(parts[i], kv, "=") == 2 && kv[1] == d) return kv[2]
      }
      print "::error::No offset for date " d > "/dev/stderr"
      exit 1
    }
    function flush(   path, i) {
      if (version == "") return
      while (nbody > 0 && body[nbody] == "") nbody--
      path = outdir "/" provider "-" module "-v" version ".md"
      printf "+++\n" > path
      printf "title = \"%s/%s v%s\"\n", provider, module, version > path
      printf "date = %sT12:00:00%s\n", date, offset_for(date) > path
      printf "slug = \"%s-%s-v%s\"\n", provider, module, version > path
      printf "description = \"%s\"\n", escaped_title > path
      printf "+++\n\n" > path
      for (i = 1; i <= nbody; i++) print body[i] > path
      close(path)
      written++
    }
    /^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ {
      flush()
      version = $0; sub(/^## \[/, "", version); sub(/\].*$/, "", version)
      date = $0; sub(/^.* - /, "", date)
      escaped_title = ""; nbody = 0; seen_title = 0
      next
    }
    version == "" { next }
    !seen_title && /^### / {
      escaped_title = substr($0, 5)
      gsub(/\\/, "\\\\", escaped_title)
      gsub(/"/, "\\\"", escaped_title)
      seen_title = 1
      skip_blank = 1
      next
    }
    !seen_title { next }
    skip_blank && $0 == "" { skip_blank = 0; next }
    { skip_blank = 0; body[++nbody] = $0 }
    END { flush(); print written + 0 }
  ' "$changelog")

  release_count=$((release_count + written))
done <<<"$changelogs"

echo "Generated ${release_count} release post(s) under ${RELEASES_CONTENT_DIR#"$REPO_ROOT"/}."
