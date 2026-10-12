#!/usr/bin/env bash
# File (or reuse) a GitHub issue for an ADR's "Out of scope" bullet, and link
# the issue back into the bullet's line(s) in-place. The ADR itself lives in
# noisypigeon/pigeon.dev under adr/infrastructure/ since ADR-0157, while the
# issue is filed against this repo by default -- see ADR-0031, ADR-0157.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: adr-issue.sh --title "..." --body "..." --label NAME [--label NAME ...]
                     --adr-line FILE:LINE [--adr-line FILE:LINE ...]
                     [--issue N] [--repo OWNER/NAME]

  --title      Issue title (required unless --issue is given).
  --body       Issue body (required unless --issue is given).
  --label      Label to ensure exists and attach; repeatable.
  --adr-line   ADR file and 1-based line number to annotate with the issue
               link, e.g. .adr-src/adr/infrastructure/0031-out-of-scope-issue-tracking.md:76;
               repeatable. Any path works; resolved relative to the CWD.
  --issue      Reuse an existing issue number instead of creating a new one.
  --repo       Repo to file the issue against (default noisypigeon/noisypigeon).
               The ADR text lives in noisypigeon/pigeon.dev, but an Out-of-scope
               item is work against this repo, so the issue belongs here. Passed
               explicitly so nothing depends on the CWD's git remote.
EOF
}

title=""
body=""
issue_num=""
repo="noisypigeon/noisypigeon"
labels=()
adr_lines=()

while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="$2"; shift 2 ;;
    --body) body="$2"; shift 2 ;;
    --label) labels+=("$2"); shift 2 ;;
    --adr-line) adr_lines+=("$2"); shift 2 ;;
    --issue) issue_num="$2"; shift 2 ;;
    --repo) repo="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ -z "$issue_num" ] && { [ -z "$title" ] || [ -z "$body" ]; }; then
  echo "Either --issue, or both --title and --body, are required." >&2
  usage >&2
  exit 1
fi

if [ ${#adr_lines[@]} -eq 0 ]; then
  echo "At least one --adr-line is required." >&2
  exit 1
fi

# name -> "color|description"
label_meta() {
  case "$1" in
    out-of-scope) echo "5319e7|Deferred item raised in an ADR's Out of scope section" ;;
    area:email-sync) echo "1d76db|IMAP sink/transform/sync pipeline" ;;
    area:dataops) echo "0e8a16|S3-compatible remote storage (bucket configs, upload)" ;;
    area:keyring) echo "fbca04|Identities, bucket configs, and encryption keys in the OS keychain" ;;
    area:job-orchestration) echo "d93f0b|pigeon job wizard, concurrency, and phase orchestration" ;;
    area:security) echo "b60205|Encryption, key management, and related crypto" ;;
    area:tooling) echo "c5def5|Dev-cycle, CI, release, and publishing tooling" ;;
    *) echo "ededed|" ;;
  esac
}

ensure_label() {
  local name="$1"
  if gh label list -R "$repo" --limit 200 --json name -q '.[].name' | grep -qxF "$name"; then
    return
  fi
  local meta color desc
  meta="$(label_meta "$name")"
  color="${meta%%|*}"
  desc="${meta#*|}"
  gh label create -R "$repo" "$name" --color "$color" --description "$desc"
  echo "Created label: $name"
}

for label in "${labels[@]}"; do
  ensure_label "$label"
done

issue_url=""
if [ -n "$issue_num" ]; then
  issue_url="$(gh issue view -R "$repo" "$issue_num" --json url -q '.url')"
  echo "Reusing issue #$issue_num: $issue_url"
else
  label_args=()
  for label in "${labels[@]}"; do
    label_args+=(--label "$label")
  done
  issue_url="$(gh issue create -R "$repo" --title "$title" --body "$body" "${label_args[@]}")"
  echo "Created issue: $issue_url"
fi

for entry in "${adr_lines[@]}"; do
  file="${entry%%:*}"
  line="${entry##*:}"
  if [ ! -f "$file" ]; then
    echo "ADR file not found, skipping: $file" >&2
    continue
  fi
  sed -i '' "${line}s@\$@ ([#${issue_url##*/}](${issue_url}))@" "$file"
  echo "Annotated $file:$line"
done

echo "Done: $issue_url"
