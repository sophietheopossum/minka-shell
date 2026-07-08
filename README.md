# MinkaShell

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
## Status — milestone M2 (widget parity, core slice)

- [x] Bar right cluster: StatusNotifier tray (left/middle/right-click per the
      SNI spec), UPower battery, CPU/RAM sampler.
- [x] Start-menu button + launcher: fuzzy-ish search over desktop entries,
      Enter launches the top hit, Escape closes, session controls
      (sleep/reboot/poweroff). Opens via bar button or the `ui.startMenu`
      broadcast (Super+A / Super tap — config now broadcasts alongside the
      legacy `ags request` so both shells respond during the transition).
- [x] Dock: revealed by the compositor's `dock.proximity` broadcast, running
      windows with focus indicator, click to activate.
- [x] Notification popups (`org.freedesktop.Notifications` server in
      `services/Notifs.qml`), panel-output only, 6s expiry, click to dismiss.
- [x] Calendar menu: bar clock toggles a Monday-first month view, today in
      red, ‹/› month paging, click the title to jump back to today.
- [x] Audio status menu: `vol` widget in the bar (click opens, scroll ±5%,
      middle-click mutes) + menu with slider/mute for default sink and
      source via PipeWire. Audio only — network is handled by CMST, per
      Sophie.
- [x] Focused-window title in the bar (per monitor, elided at 320px).
- [x] Fixes from testing: tray right-click menus are self-rendered
      (TrayMenu: PopupWindow + QsMenuOpener over the DBus menu tree) after
      both Qt platform-menu paths (display(), QsMenuAnchor) errored on
      ShojiWM; launcher search matches desktop id/exec/keywords, with
      name-prefix hits ranked first.
- [ ] M2 remainder: dock pinning (waits on dock testing). Out of scope by
      decision: clipboard menu (dropped), wallpaper switcher (moves to the
      future Minka settings utility).
- [ ] M3: `minka-fx` (Guido) takes snap preview + OSDs; drop the `ags request`
      exec path once shoji-bar-2 retires. Dock testing also waits for
      shoji-bar-2 retirement (its dock currently owns the proximity zone).

## Running

```sh
sudo pacman -S quickshell   # cachyos-extra, 0.3.0 at time of writing

qs -p /home/seirra/Documents/src/MinkaDE/MinkaShell
```

or make it the default config: `ln -s /home/seirra/Documents/src/MinkaDE/MinkaShell ~/.config/quickshell`.

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
  MenuState.qml        cross-window menu routing (Duo-aware)
  Notifs.qml           the NotificationServer (exactly one per shell)
  Theme.qml            design tokens
modules/bar/
  Bar.qml              top panel (PanelWindow, exclusive zone)
  Workspaces.qml       workspace pills bound to ShojiIpc.view
  Clock.qml            d/M/yyyy HH:mm
  SystemTrayWidget.qml Battery.qml SysUsage.qml
modules/dock/Dock.qml            proximity-revealed dock
modules/startmenu/StartMenu.qml  launcher + session controls
modules/notifications/NotifPopup.qml
```

## IPC contract (served by the ShojiWM config)

Requests: `workspaces.get`, `workspaces.switch`, `workspaces.activate`,
`workspaces.toggleTiling`, `windows.activate`.
Broadcasts consumed: `workspaces.changed`, `dock.proximity`, `snap.preview`
(snap preview moves to minka-fx in M3).
