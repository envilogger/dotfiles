# Quickshell config

A vertical Hyprland bar on the left edge, written in QML for Quickshell.

- **Run:** `quickshell -c bar`. Edits hot-reload; check `qs log -c bar`. Restart after
  changing the `//@ pragma` in `shell.qml` (needed for tray menus), or if the config
  directory is replaced (e.g. a dotfiles branch switch), which stops the file watcher.
- **Layout:** `bar/shell.qml` → `Bar.qml` (one bar per screen) → `widgets/`. A bar item
  `X.qml` opens a popup `XPanel.qml`; panels share one pattern (PopupWindow +
  HyprlandFocusGrab, Esc/click-outside to close) and are capped at
  `Theme.panelMaxHeight` of the screen.
- **Settings:** `bar/Theme.qml` (singleton) holds sizes, colours and user lists
  (`trayHidden`, `trayIcons`, `workspaceCount`, …). Use `Theme.*`, never literal colours.
- **Icons:** Tabler, all loaded from `bar/tabler/*.json` by `Tabler.qml`. Use
  `SvgIcon { name: "wifi" }` (`-filled` suffix for filled icons). Line width is
  `Theme.iconStroke`.
- **Colours / tinty:** `Theme.qml` reads a base24 palette from
  `~/.local/state/theme/palette.json`, follows it live, and falls back to Nord.
  `tinty apply <scheme>` writes that file through the global hook `tinty-hook.sh`
  (configured in `~/.config/tinted-theming/tinty/config.toml`; `items = []` is
  intentional, so tinty doesn't recolour the terminal). `~/.local/bin/frame-wallpaper`
  uses the same palette's `base00`.
- **System data** not exposed by Quickshell comes from `nmcli` (IP, DNS) and `busctl`
  (UPower history and details, BlueZ signal strength).
- **Hyprland uses a Lua config:** dispatches are Lua, e.g.
  `Hyprland.dispatch("hl.dsp.focus({ workspace = 3 })")`.
- **Testing without a screenshot tool:** add a temporary `IpcHandler` and call it with
  `qs ipc -c bar call <target> <fn>`, using `grabToImage` to save a PNG. Remove it afterwards.
