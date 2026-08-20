#!/usr/bin/env bash
# Install the golgor.notes plugin: symlink into the shell, register the bar
# widget, and add the keybinds. Idempotent — safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ID="golgor.notes"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
LINK="$PLUGINS_DIR/$PLUGIN_ID"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
BINDINGS="$HOME/.config/hypr/bindings.lua"

chmod +x "$REPO/bin/notes" "$REPO/bin/test.sh"

# 1. Symlink the repo into the shell's plugin dir (ln -sfn replaces in place).
mkdir -p "$PLUGINS_DIR"
ln -sfn "$REPO" "$LINK"
echo "linked  $LINK -> $REPO"

# 2. Add the bar widget to shell.json (right cluster) if not already present.
python3 - "$SHELL_JSON" "$PLUGIN_ID" <<'PY'
import json, sys
path, pid = sys.argv[1], sys.argv[2]
d = json.load(open(path))
right = d["bar"]["layout"]["right"]
if not any(w.get("id") == pid for w in right):
    right.insert(0, {"id": pid})
    json.dump(d, open(path, "w"), indent=2)
    open(path, "a").write("\n")
    print(f"added   {pid} to bar.layout.right")
else:
    print(f"ok      {pid} already in bar.layout.right")
PY

# 3. Add keybinds (backup first) if not already present.
if grep -q "$PLUGIN_ID" "$BINDINGS"; then
  echo "ok      keybinds already present"
else
  cp "$BINDINGS" "$BINDINGS.bak.$(date +%s)"
  cat >> "$BINDINGS" <<LUA

-- Obsidian quick-notes plugin ($PLUGIN_ID)
hl.unbind("SUPER + CTRL + N")   -- was: Toggle nightlight
o.bind("SUPER + N", "New note", "omarchy-shell $PLUGIN_ID capture")
o.bind("SUPER + CTRL + N", "Toggle notes", "omarchy-shell shell toggle $PLUGIN_ID")
LUA
  echo "added   keybinds (backup: $BINDINGS.bak.*)"
fi

# 4. Reload the shell + Hyprland. A full shell restart is needed (not just
# rescanPlugins): the plugin is a symlink, so QML edits don't hot-reload and
# an already-loaded panel is only re-instantiated on restart.
omarchy restart shell >/dev/null 2>&1 || omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true
echo "done. Press SUPER+N to capture, SUPER+CTRL+N to toggle the dropdown."
