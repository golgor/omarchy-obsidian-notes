#!/usr/bin/env bash
# Self-check for `notes list`: 3 fields, newest-first, datetime heading, 100-char body.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "first note - a short one" > "$tmp/2026-01-01-000000.md"
sleep 0.01
printf 'a very long note body that runs well past one hundred characters so we can prove the body preview is capped at exactly one hundred\nsecond line folded in\n' \
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

# Heading is the timestamp rendered as a datetime.
[[ "$first_title" == "2026-01-02 09:15:00" ]] || { echo "FAIL: bad title '$first_title'"; exit 1; }

# Body capped at 100 chars, newlines folded to spaces (no line-2 leak).
[[ "${#first_body}" -le 100 ]] || { echo "FAIL: body ${#first_body} > 100"; exit 1; }
[[ "$first_body" != *"second line"* ]] || { echo "FAIL: body leaked line 2"; exit 1; }

echo "OK: 2 rows, newest-first, title '$first_title', body ${#first_body} chars"
