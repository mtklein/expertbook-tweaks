# expertbook-tweaks

ASUS ExpertBook Ultra (B9406CAA) on Omarchy, on top of
[asus-expertbook-linux](https://github.com/burakgon/asus-expertbook-linux) (used unmodified).

## Layout

| Path | What |
|---|---|
| `home/` | Mirrors `~`. `./install.sh` links every file to the same path under `~` (the Tiger theme as one directory). |
| `system/` | Mirrors `/`. `./install.sh --system` copies it via pkexec. |
| `plugins/` | One patch per Omarchy plugin clone. `plugins/sync apply` rebuilds `~/.config/omarchy/plugins/mtklein.*` from the installed Omarchy plus its patch. |
| `hyprland-patched/`, `sddm-patched/` | Patches and `build.sh` for the Hyprland and SDDM packages. |
| `voxtype-patched/` | Patch and `build.sh` for the Voxtype dictation service. |
| `ctm/` | Source of `white-point-ctm`. |
| `tools/` | Power load tests (run with pkexec). `geforcenow-hdr-edid <file>` writes a copy of the panel's EDID with its HDR data, which the panel declares in DisplayID 2.0, restated in a CTA-861 block; meant for `GAMESCOPE_PATCHED_EDID_FILE`, not wired in. |

`~/.config/hypr/monitors.lua` stays Omarchy's file (it rewrites it with `sed -i`); `install.sh` appends two `dofile` lines to it.

## Display

| File | What |
|---|---|
| `.config/hypr/hdr.lua` | eDP-1 always in HDR, 10-bit. Brightness is the SDR white level: nits = `edp_sdr_white` × level ^ `edp_brightness_gamma` (600, 2.2). |
| `.local/bin/ambient-display` + service | Owns brightness and white point. Follows the light sensor, learns from manual changes, takes requests on `$XDG_RUNTIME_DIR/ambient-display.sock`. Raises a screen left below 15% on wake from suspend. |
| `.local/bin/hdr-brightness` | Brightness keys and the Display panel. Asks `ambient-display`; sets the level itself if the daemon is down; hands other monitors to `omarchy-brightness-display`. |
| `.local/bin/white-point` | Shift + brightness keys: `warmer`, `cooler`, or a kelvin value. |
| `.local/bin/white-point-ctm` | Holds Hyprland's colour matrix; run by `ambient-display`. |
| `.local/bin/brightness-why` | Explains the current brightness and the evidence behind it. |
| `.local/bin/hdr-monitor-state` | `omarchy-monitor-state` with the HDR brightness level, for the Display panel. |
| `.config/hypr/hypridle.conf` | Display off at 8 min, suspend at 10; both skipped in stay-awake. |
| `.config/fontconfig/conf.d/60-grayscale-antialias.conf` | Greyscale text antialiasing. |

State: `~/.local/state/ambient-display.json` (evidence), `hdr-brightness` (level, plus `user <epoch>` while a manual choice holds it), `hdr-sdr-white` and `hdr-brightness-gamma` (written by `hdr.lua`). Status: `$XDG_RUNTIME_DIR/ambient-display-status.json`.

### Hyprland patches

| Patch | What |
|---|---|
| `01-sdr-white-is-reference` | The SDR white level (`sdr_max_luminance`) is advertised to colour-managed clients as the reference luminance, and they are told when it changes: subsurfaces and surfaces not yet on screen included. |
| `02-hdr-conversion` | Everything decided in the conversion to the panel's PQ signal. `sdrbrightness` applies to every surface. The colour matrix (white point) is applied in linear light. The hardware cursor is rendered in the output's encoding. A client's HDR (PQ, HLG) content is scaled so its declared reference white lands on the SDR white level, with a knee tone map above the panel's peak. |
| `03-leds-only-on-change` | Keyboard LEDs are written only when their state changes, so the Caps Lock light can be set from sysfs. |
| `04-touchpad-scroll-as-wheel` | A window tagged `wheel_scroll` gets touchpad scrolling as wheel detents (15 units each), decided by which window holds pointer focus. GeForce NOW's stream ignores smooth scrolling and is tagged in `looknfeel.lua`. |
| `05-touch-as-mouse` | On a window tagged `touch_mouse`, the first finger is the mouse: the pointer goes to the touch and the left button follows the finger. Stock Hyprland drops touches on a window that has captured the pointer. GeForce NOW is tagged while fullscreen. |

`build.sh` rebuilds the installed version as `<pkgver>-<pkgrel>.1`; install the package it prints with `pacman -U`.

### SDDM patch

`sddm-patched/01-cancel-login.patch`, built by `sddm-patched/build.sh` the same way (without the Qt5 greeter). The daemon takes effect at the next boot.

- The helper blocks SIGINT while PAM authenticates, which is what lets pam_fprintd's own SIGINT abort fire.
- The daemon can cancel the attempt being checked (SIGINT to the helper, SIGKILL after 3 s) and reports nothing for it.
- A login that arrives while another is being checked replaces it; one that arrives once a session is starting is still refused.
- Themes get `sddm.cancelLogin()` and `sddm.canCancelLogin`.

### Voxtype patch

`voxtype-patched/01-wait-for-commands.patch` makes the service wait on a file watch of its runtime folder instead of polling it every 100 ms. `voxtype-patched/build.sh` builds the installed version from source in `~/voxtype`, installs it as `~/.local/bin/voxtype-patched` and restarts the service; `.config/systemd/user/voxtype.service.d/patched.conf` makes the service run it. The packaged `voxtype` command is untouched.

## Desktop

| File | What |
|---|---|
| `.config/hypr/bindings.lua` | Brightness and white point keys, layout cycle, dictation. |
| `.config/hypr/console-tap.lua` | A tap of Super or Caps Lock toggles the Quake console (held, or with another key, they act as usual; Caps Lock is Ctrl). The toggle happens 20 ms after the release, so the window that gains focus never sees the key as held. Windows opened from the console move to the desktop. |
| `.local/bin/attention`, `system/etc/udev/rules.d/70-capslock-led.rules` | The Caps Lock light, solid, means an agent needs input. `attention on\|off [reason]`, keyed by the calling Claude Code process; hooks in `~/.claude/settings.json` raise it for permission prompts and questions and clear it when answered. |
| `.config/hypr/input.lua` | Caps Lock is Ctrl, both Shifts toggle Caps Lock, natural scrolling. |
| `.config/hypr/looknfeel.lua` | No window borders; VRR for fullscreen windows; no second SDR copy of each HDR frame unless something is capturing the screen; Steam's main window tiles; GeForce NOW's tags for wheel scrolling and touch. |
| `.local/bin/workspace-layout-toggle` | Omarchy's layout cycle without its notification. |
| `.local/bin/bar-item`, `.config/omarchy/extensions/omarchy-menu.jsonc` | Appearance > Menu Bar > Bar Items; hides the Nightlight rows. |
| `.config/omarchy/themes/tiger/` | Mac OS X 10.4 as a light theme with a dark shell. |
| `.config/omarchy/plugins/mtklein.dictation/` | Bar widget: a microphone icon while Voxtype records (red) or transcribes (white), nothing otherwise. Needs `omarchy bar put mtklein.dictation --section center`, `voxtype config set osd.enabled false`, and a shell restart the first time. |
| `.config/fontconfig/conf.d/61-tiger-sans.conf` | Luxi Sans as the default sans-serif. |
| `system/usr/share/sddm/themes/tiger/`, `system/etc/sddm.conf.d/zz-expertbook.conf`, `system/usr/local/share/expertbook-tweaks/sddm-hyprland.lua` | Login window that copies the Omarchy lock screen: the blurred wallpaper and one password field (sizes, colours and font are the lock's values for the Tiger theme, written out by hand). The greeter's Hyprland runs the panel in HDR at the desktop's scale and last white level (`/var/lib/expertbook-tweaks/greeter-scale` from `hdr.lua`, `greeter-nits` from `ambient-display`; 200 nits if missing, never below 8). |
| `.config/omarchy/hooks/post-update.d/expertbook-tweaks` | After `omarchy update`: says in the update terminal if Hyprland or SDDM is no longer the patched build, reapplies the plugin patches. |

### Plugin patches

| Patch | What |
|---|---|
| `active-window` | App name in bold Luxi Sans; a spinner while an app is launching. |
| `workspaces` | Occupied desktops only; hidden when there is one; click cycles the layout. |
| `tray` | Icons on the bar unless listed in `drawer`; those fade in under the pointer. Shift + right-click for the pin list. |
| `clock` | Luxi Sans. |
| `weather` | Temperature beside the icon. |
| `osd` | No "Launching…" box; raises `$XDG_RUNTIME_DIR/omarchy-launching` instead. |
| `monitor` | Brightness through `hdr-brightness`; shows nits. |
| `audio`, `power`, `network`, `bluetooth`, `dropbox`, `tailscale`, `agents` | Plain status in place of the decorative phrases. |

To change a clone: edit it in `~/.config/omarchy/plugins/`, `omarchy restart shell`, then `plugins/sync record <name>`. `sync apply` refuses to overwrite a clone with unrecorded edits.

## Hardware

| File | What |
|---|---|
| `.local/bin/sdw-clash-recover` + service | Suspends and resumes the speaker sink after a SoundWire bus clash on link 2, which otherwise leaves the woofers silent. |
| `system/usr/local/bin/rapl-sync` + service | Copies the firmware's MMIO PL1/PL2 onto the MSR limits; without it every profile sustains 15 W. |
| `system/etc/modules-load.d/uinput.conf` | Steam Input needs `uinput` loaded to make virtual controllers. |
| `system/etc/udev/hwdb.d/70-pocketpad.hwdb` | Button names for the Retroid Pocket Nova as a Bluetooth gamepad (PocketPad). |
| `system/etc/systemd/system/ollama.service.d/override.conf` | Ollama on the iGPU. |
| `.local/share/fp-shim/` | Fingerprint setup for the FocalTech reader Omarchy doesn't detect: `PATH=~/.local/share/fp-shim:$PATH omarchy-setup-security-fingerprint`. `fp-storage.py` lists or clears templates on the chip. |
| `system/etc/pam.d/sddm`, `system/etc/pam.d/login`, `system/usr/local/share/expertbook-tweaks/password-given` | Fingerprint at the login screen and at console login; skipped while the lid is closed. At the login screen an empty login is a fingerprint wait (up to 5 minutes, failing without touching faillock) and a typed password skips the reader. The theme keeps one such wait running while the field is empty and cancels it on the first keystroke, which needs the patched SDDM; on stock SDDM it is password-only. The fingerprint icon shows while pam_fprintd is waiting. The stock files are kept beside them as `*.before-fingerprint`. |

## Games and TV

| File | What |
|---|---|
| `.local/bin/game`, `.config/MangoHud/MangoHud.conf` | Steam launch option `game %command%`: native Wayland window, MangoHud hidden until Right Shift + F12. |
| `.local/share/flatpak/overrides/com.nvidia.geforcenow` | GeForce NOW uses the Flatpak runtime's SDL (`SDL_DYNAMIC_API`) in place of its bundled one, which was built without Xcursor and turns the game's cursors into two-colour blobs. |
| `.local/bin/tv-mode` + service, `.config/hypr/tv-mode.lua` | A 1080p TV plus power turns the laptop into a Big Picture console. Run only against its simulator so far (`tv-mode sim …`). |

## Not obvious

- Changing focus from a Lua key handler while that key is still being processed leaves XWayland believing the key is held (it arrives in the new window's list of pressed keys and is never released there). X11 apps then see every key with that modifier: this is what broke typing in GeForce NOW.
- F14 stays unbound: the firmware sends it on every USB-C power plug and unplug.
- KMS applies the colour matrix to the encoded signal, which is wrong for PQ; `02-hdr-conversion` is why kelvin values are true.
- Only one client may hold the colour matrix. hyprsunset must not run; `ambient-display` kills it if it does.
- Hyprland draws window borders at a fixed 80 nits whatever the SDR white level, hence no borders.
- Subpixel antialiasing on transparent layers overshoots white in HDR, hence greyscale (fontconfig, and `QSG_DISTANCEFIELD_ANTIALIASING` for Qt Quick).
- An official Hyprland update replaces the patched build.
- HDR is relative here: a game's white is its declared reference white (203 nits when it declares none), drawn at the desktop's white. Set a game's paper white to 203. Chromium declares the advertised white as its reference, so it is scaled by 1.
- `omarchy theme set` rewrites `/etc/chromium/policies/managed/color.json`; delete it again for stock Chromium colours.
- Turning a clone off makes Omarchy put the stock widget back; `bar-item` disables both.
- Each read of the light sensor blocks about a second.
- Stock Hyprland rewrites the keyboard LEDs on every key event, which flickers the attention light; `03-leds-only-on-change` stops that, and `attention` still re-asserts the light in case the Caps Lock state changes.
- Hyprland's Lua key event carries xkb keycodes (evdev + 8).
- The Tiger wallpaper is Apple's artwork: fetched by `install.sh`, not committed.

## Packages added to Omarchy

`libfprint-git` `fprintd` · `ollama` `ollama-vulkan` · `hypridle` · `socat` · `mangohud` · `ttf-dejavu` `ttf-dejavu-nerd` · `ttf-luxi` (AUR; `makepkg --skippgpcheck`, tarball sha256 pinned) · `cmake` `glaze` `hyprland-protocols` `hyprwayland-scanner` (to build Hyprland) · `extra-cmake-modules` `qt6-tools` `python-docutils` (to build SDDM) · `rust` (to build Voxtype).

## License

MIT; see `LICENSE`. The plugin patches carry context lines from Omarchy's plugins, Copyright (c) David Heinemeier Hansson, MIT; see `plugins/LICENSE.omarchy`.
