# omarchy-obsidian-notes — v1 spec

Quick-capture notes into an Obsidian vault, and browse recent ones from an
Omarchy bar dropdown.

## Goal

Capture a note in one keystroke without opening Obsidian. See recent notes in
a dropdown and copy one back to the clipboard.

## Settled decisions

| Topic | Decision |
|-------|----------|
| Vault / destination | `$NOTES_DIR` env var (default `~/Documents/Notes`) |
| Storage | One `.md` file per note |
| Filename | Timestamp: `YYYY-MM-DD-HHMMSS.md` (no collisions, no sanitizing) |
| File content | Exactly the text you typed |
| Capture UI | `zenity --entry` popup (only prompt tool installed; no app switch) |
| Dropdown row | Bold datetime heading + up to 100-char body preview, divider between |
| Dropdown order | Newest first (by modification time) |
| Click a note | Copy its full text to the clipboard (`wl-copy`) |
| Code location | This repo in `~/Code/Personal/`, symlinked into the shell |
| Plugin id | `golgor.notes` (Omarchy bar-widget) |

## Keybinds

| Key | Action | Note |
|-----|--------|------|
| `SUPER + N` | New note (zenity capture) | new binding |
| `SUPER + CTRL + N` | Toggle the notes dropdown | replaces default Toggle nightlight |
| `SUPER + SHIFT + N` | (unchanged — still Editor) | left as-is |

## Parts

- `bin/notes` — one script, three subcommands: `capture`, `list`, `copy`.
- `manifest.json`, `BarWidget.qml`, `Panel.qml` — the Omarchy bar-widget.
- `install.sh` — symlink the plugin, register the bar widget, add the keybinds.

## Deferred (later iterations)

- `j`/`k` to move, `Enter` to copy (keyboard-driven dropdown).
- Right-click or an icon to open the note in Obsidian.
- Readable title-based filenames.
- Multi-line capture.
