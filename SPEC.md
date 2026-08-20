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
| File content | Exactly the text you typed (supports multi-line notes) |
| Capture UI | Quickshell QML capture overlay (`CaptureOverlay.qml`) |
| Dropdown row | Bold datetime heading + up to 100-char body preview, divider between |
| Dropdown order | Newest first (by modification time) |
| Click a note | Copy its full text to the clipboard (`wl-copy`) |
| Code location | This repo in `~/Code/Personal/`, symlinked into the shell |
| Plugin id | `golgor.notes` (Omarchy bar-widget) |

## Keybinds

| Key | Action | Note |
|-----|--------|------|
| `SUPER + N` | New note (QML capture overlay) | new binding |
| `SUPER + CTRL + N` | Toggle the notes dropdown | replaces default Toggle nightlight |
| `SUPER + SHIFT + N` | (unchanged — still Editor) | left as-is |

## Parts

- `bin/notes` — one script, three subcommands: `capture`, `list`, `copy`.
- `manifest.json`, `BarWidget.qml`, `Panel.qml` — the Omarchy bar-widget.
- `install.sh` — symlink the plugin, register the bar widget, add the keybinds.

## Deferred (later iterations)

- Right-click or an icon to open the note in Obsidian.
- Readable title-based filenames.
