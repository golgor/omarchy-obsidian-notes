# omarchy-obsidian-notes

A small Omarchy bar-widget for quick Obsidian note capture.

- `SUPER + N` — pop a text box, type a note, it is saved to the vault.
- `SUPER + CTRL + N` — toggle a dropdown of recent notes; click one to copy it.

Notes are one `.md` file each in the folder named by `$NOTES_DIR`
(default `~/Documents/Notes` — see **Configure your vault** below). Filenames
are timestamps; the dropdown shows a datetime heading plus a ~100-char preview.

## Configure your vault

The vault path is read from the `NOTES_DIR` environment variable (default
`~/Documents/Notes`). On Omarchy (a uwsm/systemd session), set it in Hyprland
so both the dropdown (`omarchy-shell`) and the `SUPER+N` keybind inherit it.
Add to `~/.config/hypr/hyprland.lua`:

```lua
-- Hyprland's env does not expand $HOME, so use a literal absolute path.
hl.env("NOTES_DIR", "/home/<you>/Documents/MyVault/Notes")
```

Relaunch Hyprland to apply (`SUPER + ESC` → Relaunch, or log out and back in).
Hyprland's autostart imports its env into the systemd user session, so the
value reaches the graphical shell as well as keybind-spawned commands.

To apply to the **current** session without relaunching:

```bash
systemctl --user set-environment NOTES_DIR="/home/<you>/Documents/MyVault/Notes"
dbus-update-activation-environment --systemd NOTES_DIR
omarchy restart shell
```

> `~/.bashrc` does **not** work here: it is only sourced by interactive
> terminals, not by the uwsm-launched `omarchy-shell`.

## Install

```bash
./install.sh          # symlink, register bar widget, add keybinds, reload
```

Re-run any time — it is idempotent. Keybinds are appended to
`~/.config/hypr/bindings.lua` (backed up first), and the bar widget is added
to `~/.config/omarchy/shell.json`.

## Test

```bash
./bin/test.sh         # self-check for the list/preview logic
```

## Developing

The plugin is symlinked into the shell, so **QML edits do not hot-reload**.
After changing `BarWidget.qml` / `Panel.qml`, restart the shell:

```bash
omarchy restart shell
```

`bin/notes` changes take effect immediately (the script runs fresh each open).

## Layout

- `bin/notes` — `capture` / `list` / `copy` subcommands (all the logic).
- `BarWidget.qml`, `Panel.qml`, `manifest.json` — the Omarchy bar-widget.
- `install.sh` — wiring. `SPEC.md` — the v1 spec and deferred ideas.
