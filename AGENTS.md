# AGENTS.md

Guidance for working on this plugin. It is small — keep it that way.

## Architecture: one seam

`bin/notes` is the **deep module**. All note and vault logic lives there,
behind a three-verb **interface**:

- `notes capture` — prompt (zenity) and write a new note.
- `notes list` — print `path⇥title⇥body`, one line per note, newest first.
- `notes copy <path>` — copy a note's text to the clipboard.

The QML (`BarWidget.qml`, `Panel.qml`) is a thin **adapter** over that seam:
it renders the dropdown and calls `bin/notes`. It does not know how notes are
stored.

**The rule:** note/vault behaviour goes in `bin/notes`; QML only presents.

So QML must NOT:
- contain the vault path, a filesystem path, or a glob;
- parse timestamps or filenames;
- read or write note files directly.

New behaviour = a new or extended `bin/notes` verb that QML calls. This keeps
the logic testable from a plain shell (no compositor needed) and keeps each
change local to one file.

## Interface contract (do not break silently)

`notes list` emits tab-separated `path⇥title⇥body`, newest first. `Panel.qml`
splits on the tab and expects three fields. Change the format and you change
both sides plus `bin/test.sh`.

## Configuration

The vault path comes only from `$NOTES_DIR` (default `~/Documents/Notes`).
Never hardcode a personal or company path — this repo is public. Per-user
setup lives in `~/.config/hypr/hyprland.lua` (see README).

## Tests

Non-trivial script logic keeps one check in `bin/test.sh` (plain asserts, no
framework). Run `./bin/test.sh`. Add a case when you touch the list/preview
logic.

## Dev workflow

- The plugin is symlinked into `~/.config/omarchy/plugins/`. QML edits do NOT
  hot-reload — run `omarchy restart shell` to apply them. `bin/notes` changes
  take effect on the next dropdown open.
- No new dependencies. Coreutils + `zenity` + `wl-copy` only.

## Branch & PR workflow

`main` is protected — no direct pushes. Work one PR per issue.

- Branch from `main`: `git switch -c <issue-number>-short-desc` (e.g. `1-keyboard-nav`).
- Keep the PR scoped to that one issue and reference it in the description: `Closes #<n>`.
- Before opening the PR: `./bin/test.sh` passes and `omarchy restart shell`
  loads the plugin without QML errors.

## Ponytail

Prefer the smallest change that works. No abstraction for a single caller, no
config for a constant, no scaffolding "for later". Deletion beats addition.
If a simplification cuts a real corner, mark it with a `ponytail:` comment
naming the ceiling.
