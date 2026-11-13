# expertbook-tweaks

ASUS ExpertBook Ultra (B9406CAA) on Omarchy, on top of
[asus-expertbook-linux](https://github.com/burakgon/asus-expertbook-linux) (used unmodified).

## Layout

| Path | What |
|---|---|
| `home/` | Mirrors `~`. `./install.sh` links every file to the same path under `~` (the Tiger theme as one directory). |
| `system/` | Mirrors `/`. `./install.sh --system` copies it via pkexec. |
| `hyprland-patched/`, `sddm-patched/` | Patches and `build.sh` for the Hyprland and SDDM packages. |
| `ctm/` | Source of `white-point-ctm`. |
| `tools/` | Power load tests (run with pkexec). `click X,Y [sleepS] [mX,Y] …` clicks or moves a synthetic pointer at logical coordinates on a 1600×1000 layout, for testing the shell. `geforcenow-hdr-edid <file>` writes a copy of the panel's EDID with its HDR data, which the panel declares in DisplayID 2.0, restated in a CTA-861 block; meant for `GAMESCOPE_PATCHED_EDID_FILE`, not wired in. |

No Omarchy package is left except `omarchy-keyring`, which goes with its repository. That repository is still listed (last) in `pacman.conf` and supplies a few third-party packages Arch does not: the fingerprint library, `tzupdate`, the boot-menu tools. The icon theme is Arch's Adwaita (`gsettings set org.gnome.desktop.interface icon-theme Adwaita`).

## Display

| File | What |
|---|---|
| `.config/hypr/display.lua` | The display setup. The panel's scale cycles through 1.5, 1.8 and 2 on Fn+F8 and is kept in `~/.local/state/edp-scale`. eDP-1 always in HDR, 10-bit. Brightness is the SDR white level: nits = `edp_sdr_white` × level ^ `edp_brightness_gamma` (600, 2.2). With the lid closed and another monitor attached the panel is off (`edp_lid`), and it comes back when the lid opens or the last other monitor goes. |
| `.local/bin/ambient-display` + service | Owns brightness and white point. Follows the light sensor, learns from manual changes, takes requests on `$XDG_RUNTIME_DIR/ambient-display.sock`. Raises a screen left below 15% on wake from suspend. |
| `.local/bin/hdr-brightness` | Brightness keys. Asks `ambient-display`; sets the level itself if the daemon is down; does nothing for other monitors. |
| `.local/bin/white-point` | Shift + brightness keys: `warmer`, `cooler`, or a kelvin value. |
| `.local/bin/white-point-ctm` | Holds Hyprland's colour matrix; run by `ambient-display`. |
| `.local/bin/brightness-why` | Explains the current brightness and the evidence behind it. |
| `.config/hypr/hypridle.conf` | Display off at 8 min, suspend at 10; both skipped in stay-awake. Locks before every suspend and holds the suspend until the lock is drawn. |
| `.config/fontconfig/conf.d/60-grayscale-antialias.conf` | Greyscale text antialiasing. |

State: `~/.local/state/ambient-display.json` (evidence), `hdr-brightness` (level, plus `user <epoch>` while a manual choice holds it), `hdr-sdr-white` and `hdr-brightness-gamma` (written by `display.lua`). Status: `$XDG_RUNTIME_DIR/ambient-display-status.json`.

### Hyprland patches

| Patch | What |
|---|---|
| `01-sdr-white-is-reference` | The SDR white level (`sdr_max_luminance`) is advertised to colour-managed clients as the reference luminance, and they are told when it changes: subsurfaces and surfaces not yet on screen included. |
| `02-hdr-conversion` | Everything decided in the conversion to the panel's PQ signal. `sdrbrightness` applies to every surface. The colour matrix (white point) is applied in linear light. The hardware cursor is redrawn when the brightness or white point changes. A client's HDR (PQ, HLG) content is scaled so its declared reference white lands on the SDR white level, with a knee tone map above the panel's peak. |
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

## Desktop

| File | What |
|---|---|
| `.config/quickshell/` | Our own shell (Quickshell), run by `shell.service`; after an edit, `systemctl --user restart shell`. `shell.qml` lists the parts and `Bar.qml` is the bar's fixed layout. Bar: workspaces that have windows, shown only when there is more than one (`Workspaces.qml`); tray icons with Bluetooth and stay-awake appearing under the pointer (`Tray.qml`); weather; Wi-Fi; battery; clock. Panels open from their icon (`Panel.qml`, one at a time; a click anywhere else or Escape closes them). The bar sits on the layer beneath windows: on the top layer, Hyprland hands focus to the last window, hidden console included, whenever something closes with the pointer over it: battery level, watts and time left; Wi-Fi on/off, networks, password to join; Bluetooth on/off, devices, connect, pair. `Osd.qml` is the volume, brightness, white point and keyboard backlight pop-up; `Audio.qml` the volume and mute keys; `Menu.qml` the app launcher and the power menu (log out, restart, shut down); `Polkit.qml` the permission prompt; `Lock.qml` the lock screen (password or fingerprint, PAM files in `pam/`), which locks again if the shell restarts while locked; `Wallpaper.qml` the wallpaper, the login screen's image; it redraws one pixel every 0.4 s for its first 5 s and once more at 8 s, because the panel otherwise self-refreshes from a banded, green-tinged frame captured right after the session's first modeset until something else updates the screen. `Theme.qml` holds colours, fonts and sizes. From scripts: `qs ipc call osd pop <icon> <percent> <text>`, `qs ipc call lock lock`, `qs ipc call menu open\|power`. |
| `.config/systemd/user/shell.service` | Runs the shell in the graphical session and restarts it if it fails. |
| `.local/bin/terminal-here` | Super+Return: a terminal in the directory of the focused terminal's shell. |
| `.local/bin/keyboard-backlight` | `up`, `down`, `cycle` for the keyboard backlight key. |
| `.bashrc` | A plain shell: `~/.local/bin` on `PATH`, `vim` as the editor, history, completion, a bare prompt. Omarchy's shell setup is not loaded. |
| `.config/environment.d/10-omarchy-fcitx.conf` | Empty; masks the Omarchy file of the same name that points every app at the removed input-method framework. |
| `.config/hypr/hyprland.lua` | Our own Hyprland config; loads the files below. Omarchy's Hyprland defaults are not loaded. |
| `.config/hypr/keys.lua` | Every keybinding: terminal, browser, the menu key, the power key, Fn+F8 to cycle the display scale, close window, full screen, workspaces 1-3, copy and paste, volume, brightness, white point, keyboard backlight, lid switch. |
| `.config/hypr/console.lua` | The Quake console: a tap of Caps Lock toggles it (held, or with another key, Caps Lock is Ctrl); sized to half the screen; stray windows opened into it move to the workspace. |
| `.config/hypr/inputs.lua` | US layout, Caps Lock is Ctrl, both Shifts toggle Caps Lock, natural scrolling, key repeat. |
| `.config/hypr/look.lua` | Gaps, rounding, shadows, animations; no window borders; VRR for fullscreen windows; no second SDR copy of each HDR frame unless something is capturing the screen. |
| `.config/hypr/windows.lua` | Window and layer rules: dialogs float, Steam's main window tiles and closing Steam's windows runs `steam-quit-when-closed`, GeForce NOW's tags for wheel scrolling and touch. |
| `.config/hypr/env.lua`, `helpers.lua`, `start.lua` | Session environment; the `o.bind` / `o.window` helpers; what starts at login. |
| `.local/bin/attention`, `system/etc/udev/rules.d/70-capslock-led.rules` | The Caps Lock light, solid, means an agent needs input. `attention on\|off [reason]`, keyed by the calling Claude Code process; hooks in `~/.claude/settings.json` raise it for permission prompts and questions and clear it when answered. |
| `.local/bin/steam-quit-when-closed` | Shuts Steam down a few seconds after its last window closes, unless a game is running, Steam has only just started, or TV mode is on. Steam never sits in the tray. |
| `.config/omarchy/themes/tiger/` | The Omarchy theme the terminal and app colours were generated from (the generated copies live in `~/.local/state/omarchy/current/theme`); `install.sh` fetches the wallpaper into it for the login screen. Nothing reads it now. |
| `.config/fontconfig/conf.d/61-default-sans.conf` | DejaVu Sans as the default sans-serif; it is also the shell's and the GTK interface font. |
| `system/usr/share/sddm/themes/tiger/`, `system/etc/sddm.conf.d/zz-expertbook.conf`, `system/usr/local/share/expertbook-tweaks/sddm-hyprland.lua` | Login window that copies the Omarchy lock screen: the blurred wallpaper and one password field (sizes, colours and font are the lock's values for the Tiger theme, written out by hand). The greeter's Hyprland runs the panel in HDR at the desktop's scale and last white level (`/var/lib/expertbook-tweaks/greeter-scale` from `display.lua`, `greeter-nits` from `ambient-display`; 200 nits if missing, never below 8). |

## System settings

Kept from Omarchy's settings package under our own file names (MIT, see `LICENSE.omarchy`).

| File under `system/` | What |
|---|---|
| `etc/mkinitcpio.conf.d/expertbook.conf` | Boot image hooks: splash, disk unlock, snapshot boot; Thunderbolt early. |
| `etc/limine-entry-tool.d/expertbook.conf` | Boot menu: one unified kernel image, quiet boot, six snapshot entries. Rebuild with `limine-mkinitcpio`. |
| `etc/plymouth/plymouthd.conf` | The stock `spinner` boot splash, which also asks for the disk password. |
| `etc/sddm.conf.d/zz-expertbook.conf` | The login screen running on Wayland. The session is Hyprland's own `hyprland-uwsm.desktop`. |
| `etc/systemd/logind.conf.d/expertbook.conf` | The power key is left to the shell's power menu; 15 s for the lock to draw before sleep. |
| `etc/systemd/system.conf.d/`, `user.conf.d/`, `system/user@.service.d/` | 5 s stop timeouts; high open-file limits (games). |
| `etc/systemd/oomd.conf.d/`, `etc/systemd/user/app.slice.d/` | Apps under sustained memory pressure are killed. |
| `etc/systemd/user/wayland-wm@hyprland.desktop.service.d/` | Logging out stops the compositor first and the rest after. |
| `etc/systemd/user/bt-agent.service` | Pairing agent the Bluetooth panel relies on. |
| `etc/systemd/zram-generator.conf.d/`, `etc/sysctl.d/90-expertbook.conf`, `etc/udev/rules.d/60-expertbook-io-scheduler.rules` | Compressed RAM swap the size of RAM with matching memory tuning; BBR; more file watchers; the kyber disk scheduler. |
| `usr/lib/systemd/system-sleep/unmount-fuse` | Unmounts GVFS mounts before sleep and restarts GVFS after. |
| `etc/systemd/resolved.conf.d/`, `etc/NetworkManager/conf.d/expertbook-wifi-powersave.conf`, `etc/modprobe.d/expertbook-usb-autosuspend.conf` | mDNS left to Avahi; Wi-Fi power save off; USB autosuspend off. |
| `etc/systemd/system/*pcr*`, `*tpm2*`, `*binfmt*`, `plocate-updatedb.service.d/` | Boot services that would report failure on this machine; file index only on mains and skipping snapshots. |
| `etc/xdg/mimeapps.list`, `etc/gnupg/dirmngr.conf` | Default apps for folders, images and PDFs; key servers. |

| File under `home/` | What |
|---|---|
| `.inputrc`, `system/etc/modprobe.d/expertbook-no-beep.conf` | No bell from the shell and no PC speaker. With desktop event sounds off (`gsettings set org.gnome.desktop.sound event-sounds false`, `org.gnome.desktop.wm.preferences audible-bell false`) and `[bell] system=no` in `foot.ini`, the system itself makes no alert sounds; apps keep their own settings. |
| `.config/uwsm/env` | Session environment: `~/.local/bin` on `PATH` (Claude Code lives there, from Anthropic's installer, and updates itself), `vim`, `foot`. |

## Hardware

| File | What |
|---|---|
| `.local/bin/sdw-clash-recover` + service | Suspends and resumes the speaker sink after a SoundWire bus clash on link 2, which otherwise leaves the woofers silent. |
| `system/etc/modprobe.d/expertbook-fnlock.conf` | Starts each boot with Fn-lock in the other state from the driver's default (`asus_wmi fnlock_default=N`), so Fn+Esc is not needed after every boot. Rebuild the boot image after changing it (`limine-mkinitcpio`). |
| `system/usr/local/share/expertbook-tweaks/lightbar-off`, `system/etc/systemd/system/lightbar-off.service` | Early in boot, switches off the firmware lighting effects of the light bar under the screen (ASUS WMI device 0x00050028, argument 0x80, through `asus-nb-wmi`'s debugfs). The firmware turns them back on at every power-on, so the bar still pulses until this runs. |
| `system/usr/local/bin/rapl-sync` + service | Copies the firmware's MMIO PL1/PL2 onto the MSR limits; without it every profile sustains 15 W. |
| `system/etc/modules-load.d/uinput.conf` | Steam Input needs `uinput` loaded to make virtual controllers. |
| `system/etc/udev/hwdb.d/70-pocketpad.hwdb` | Button names for the Retroid Pocket Nova as a Bluetooth gamepad (PocketPad). |
| `system/etc/systemd/system/ollama.service.d/override.conf` | Ollama on the iGPU. |
| `.local/share/fp-shim/fp-storage.py` | Lists or clears fingerprint templates on the FocalTech reader's chip. Enrol with `fprintd-enroll`. |
| `system/etc/pam.d/sddm`, `system/etc/pam.d/login`, `system/usr/local/share/expertbook-tweaks/password-given`, `lid-closed` | Fingerprint at the login screen and at console login; skipped while the lid is closed (`lid-closed`, which `install.sh --system` also puts into the sudo and polkit files). At the login screen an empty login is a fingerprint wait (up to 5 minutes, failing without touching faillock) and a typed password skips the reader. The theme keeps one such wait running while the field is empty and cancels it on the first keystroke, which needs the patched SDDM; on stock SDDM it is password-only. The fingerprint icon shows while pam_fprintd is waiting. The stock files are kept beside them as `*.before-fingerprint`. |

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
- Each read of the light sensor blocks about a second.
- Stock Hyprland rewrites the keyboard LEDs on every key event, which flickers the attention light; `03-leds-only-on-change` stops that, and `attention` still re-asserts the light in case the Caps Lock state changes.
- Hyprland's Lua key event carries xkb keycodes (evdev + 8).
- The Tiger wallpaper is Apple's artwork: fetched by `install.sh`, not committed.

## Omarchy is frozen

Packages come from the Arch mirrors in `system/etc/pacman.d/mirrorlist`, not Omarchy's delayed mirror; Omarchy's own repo is still configured for its kernel and a few other packages. `install.sh --system` lists Omarchy's repository last in `/etc/pacman.conf`, so anything Arch also packages (Quickshell) comes from Arch. Update with `sudo pacman -Syu`.

## Packages added to Omarchy

`libfprint-git` `fprintd` · `ollama` `ollama-vulkan` · `hypridle` · `socat` · `mangohud` · `ttf-dejavu` `ttf-dejavu-nerd` · `cmake` `glaze` `hyprland-protocols` `hyprwayland-scanner` (to build Hyprland) · `extra-cmake-modules` `qt6-tools` `python-docutils` (to build SDDM).

Removed from Omarchy: `herdr`, the titlebar plugin, the input-method framework (`fcitx5`), the video wallpaper engine (`owe`), Omarchy's Neovim setup and Neovim, Docker, printing, Moonlight, the capture tools (screen recorder, colour picker, OCR, QR), the virtual-webcam module, and the command-line extras its shell setup used (`eza`, `bat`, `zoxide`, `fzf`, `starship`, `tmux`, `lazygit`, `tldr`, `yt-dlp`, `fastfetch`). `SUPER + CTRL + RETURN` no longer does anything.

## License

MIT; see `LICENSE`. Files adopted from Omarchy are Copyright (c) David Heinemeier Hansson, MIT; see `LICENSE.omarchy`.
