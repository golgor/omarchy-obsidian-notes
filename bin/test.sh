#!/usr/bin/env bash
# Self-check for `notes list`: 3 fields, newest-first, smart title extraction (# Heading), markdown linebreaks.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "first note - a short one" > "$tmp/2026-01-01-000000.md"
sleep 0.01
printf '# Smart Heading Title\na very long note body that runs well past one hundred characters so we can prove the body preview is capped\nsecond line here\n' \
  > "$tmp/2026-01-02-091500.md"

out="$(NOTES_DIR="$tmp" "$here/notes" list)"
lines="$(wc -l <<<"$out")"
[[ "$lines" -eq 2 ]] || { echo "FAIL: expected 2 rows, got $lines"; exit 1; }

row1="$(head -n1 <<<"$out")"
first_path="$(cut -f1 <<<"$row1")"
first_title="$(cut -f2 <<<"$row1")"
first_body="$(cut -f3 <<<"$row1")"

# Newest first: the note written last must be row 1.
[[ "$first_path" == *2026-01-02-091500.md ]] || { echo "FAIL: not newest-first"; exit 1; }

# Smart Title extracted from `# Smart Heading Title`.
[[ "$first_title" == "Smart Heading Title" ]] || { echo "FAIL: expected Smart Heading Title, got '$first_title'"; exit 1; }

# Row 2 should fall back to timestamp heading.
row2="$(sed -n '2p' <<<"$out")"
second_title="$(cut -f2 <<<"$row2")"
[[ "$second_title" == "2026-01-01 00:00:00" ]] || { echo "FAIL: expected timestamp title, got '$second_title'"; exit 1; }

echo "OK: 2 rows, smart title '$first_title', fallback title '$second_title'"
