# minka-shell

Quickshell (Qt6/QML) half of the Minka hybrid shell. Owns the widget- and
service-heavy surfaces (bar, menus, tray, notifications); the Guido (Rust +
wgpu) process `minka-fx` will own transient animated overlays. Both are peers
on ShojiWM's NDJSON IPC socket — see `ARCH_MAP.md` in the repo root and the
design artifact for the full architecture.

## Status — milestone M1 (skeleton)

- [x] `ShojiIpc` singleton: non-blocking NDJSON client for
      `$XDG_RUNTIME_DIR/shojiwm-$WAYLAND_DISPLAY.sock`, auto-reconnect on
      config hot-reload, id-correlated requests, reactive `view`.
- [x] `ShellLayout` singleton: Zenbook Duo role resolution — panels pin to the
      1920x515 ScreenPad when present, KDE-style layout otherwise.
- [x] `Theme` singleton: Eternal Darkness tokens (black/red, purple tertiary).
- [x] Bare bar per output: live workspaces (click to activate, middle-click to
      toggle tiling) + clock + IPC health dot.
- [ ] M2: port remaining shoji-bar-2 widgets (dock, start menu, status menus,
      tray, notifications).
- [ ] M3: `minka-fx` (Guido) takes snap preview + OSDs; replace `ags request`
      execs with `ui.*` broadcasts.

## Running

```sh
sudo pacman -S quickshell   # cachyos-extra, 0.3.0 at time of writing

qs -p /home/seirra/Documents/src/MinkaDE/minka-shell
```

or make it the default config: `ln -s /home/seirra/Documents/src/MinkaDE/minka-shell ~/.config/quickshell`.

Requires a running ShojiWM session whose config creates the IPC server
(`createIpcServer()` — already present in `~/.config/shojiwm/src/index.tsx`).
shoji-bar-2 can keep running simultaneously; broadcasts fan out to every
connected client, which makes side-by-side parity comparison easy.

## Layout

```
shell.qml              entry point: per-screen Variants
services/
  ShojiIpc.qml         IPC singleton (socket, reconnect, reactive state)
  ShellLayout.qml      monitor role policy (Duo mode)
  Theme.qml            design tokens
modules/bar/
  Bar.qml              top panel (PanelWindow, exclusive zone)
  Workspaces.qml       workspace pills bound to ShojiIpc.view
  Clock.qml
```

## IPC contract (served by the ShojiWM config)

Requests: `workspaces.get`, `workspaces.switch`, `workspaces.activate`,
`workspaces.toggleTiling`, `windows.activate`.
Broadcasts consumed: `workspaces.changed`, `dock.proximity`, `snap.preview`
(snap preview moves to minka-fx in M3).
