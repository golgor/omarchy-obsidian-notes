# AGENTS.md

Guidance for working on this plugin. Keep it small, deep, and correct.

## Architecture: one seam

`bin/notes` is the **deep module**. All note and vault logic lives there,
behind a four-verb **interface**:

- `notes capture [text]` — save a timestamped note (from argument or stdin).
- `notes list` — print `path⇥title⇥body`, one line per note, newest first.
- `notes copy <path>` — copy a note's text to the clipboard.
- `notes delete <path>` — move a note to the system trash (`gio trash`).

The QML (`BarWidget.qml`, `Panel.qml`, `CaptureOverlay.qml`) is a thin **adapter**
over that seam: it renders the UI and calls `bin/notes`.

**The rule:** note/vault logic lives in `bin/notes`; QML only presents.

QML presents UI only:
- Keep filesystem paths, globs, and vault logic out of QML.
- Keep timestamp parsing out of QML.
- Keep file read/write operations out of QML.

New behavior = a new or extended `bin/notes` verb that QML calls.

## Interface contract

`notes list` emits tab-separated `path⇥title⇥body`, newest first. `Panel.qml`
splits on tabs and expects three fields. Newlines inside `body` are encoded as
literal `\n` in the TSV stream so single-line TSV parsing stays unbroken;
`Panel.qml` decodes `\n` back to linebreaks for `Text.MarkdownText`. Updating
this format requires updating both sides and `bin/test.sh`.

## Configuration

The vault path comes from `$NOTES_DIR` (default `~/Documents/Notes`). Session
environment variables must be set in `~/.config/hypr/hyprland.lua` via
`hl.env("NOTES_DIR", "/path")` so Hyprland exports them to the systemd user
session at login. (`.bashrc` does not reach `omarchy-shell`).

## QML patterns & gotchas

- **BorderSurface padding:** `BorderSurface` children that fill parent directly
  bypass internal padding. Anchor inner containers to `card.contentTopInset`,
  `card.contentLeftInset`, `card.contentRightInset`, and `card.contentBottomInset`.
- **Shortcut IPC toggle:** Keybinding actions (`SUPER+N`, `SUPER+CTRL+N`) must
  toggle (`opened ? close() : open()`) rather than force-open, so pressing the
  shortcut again closes the UI.
- **Markdown & Escaped Linebreaks:** `Panel.qml` renders previews with
  `textFormat: Text.MarkdownText`. TSV body linebreaks are encoded as `\n` in
  `bin/notes list` and decoded in QML (`replace(/\\n/g, "\n")`) so single-line
  TSV parsing remains intact.

## Tests & self-documentation loop

- **Test check:** Non-trivial script logic keeps a check in `bin/test.sh`. Run
  `./bin/test.sh` before PRs.
- **Documentation loop:** After completing changes, review `AGENTS.md` and
  `SPEC.md` to prune stale instructions and record new structural findings or
  gotchas.

## Dev workflow & PRs

- **Dev workflow:** The plugin is symlinked into `~/.config/omarchy/plugins/`.
  QML edits do NOT hot-reload — run `omarchy restart shell` to apply them.
  `bin/notes` changes take effect on the next dropdown open.
- **Dependencies:** Coreutils + `wl-copy` + `gio` only.
- **PR workflow:** `main` is protected. Work on feature branches (`<issue>-desc` or `docs/<desc>`),
  reference `Closes #<n>` if applicable, and open one PR per issue.

## Ponytail

Prefer the smallest change that works. No abstraction for a single caller, no
config for a constant, no scaffolding "for later". Deletion beats addition.
If a simplification cuts a real corner, mark it with a `ponytail:` comment.
