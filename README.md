# expertbook-tweaks

ASUS ExpertBook Ultra (B9406CAA) on Omarchy, on top of
[asus-expertbook-linux](https://github.com/burakgon/asus-expertbook-linux) (used unmodified).

## Layout

| Path | What |
|---|---|
| `home/` | Mirrors `~`. `./install.sh` links every file to the same path under `~` (the shell as one directory). |
| `system/` | Mirrors `/`. `./install.sh --system` copies it via pkexec. |
| `hyprland-patched/` | Patches and `build.sh` for the Hyprland package. |
| `ctm/` | Source of `white-point-ctm`. |
| `fingerprint-prompts.po` | English "translation" of fprintd's prompts, installed as `/usr/share/locale/en/LC_MESSAGES/fprintd.mo`: the text prompts (`sudo` in a terminal) start with the same fingerprint glyph the lock screen and the password box show. |
| `geforcenow-hdr/` | What the `geforcenow` launcher needs to get HDR out of NVIDIA's Flatpak client. `edid <file>` writes a copy of the panel's EDID with its HDR data, which the panel declares in DisplayID 2.0, restated in a CTA-861 block the client can read. `redirect.so` (from `redirect.c`) is preloaded into the client and shows it the files in `steamos/` in place of `os-release` and the DMI names, so it reports itself as a Lenovo SteamOS handheld: NVIDIA's service offers HDR only to SteamOS, and 120 FPS on SteamOS only to that device. |
| `tools/` | Power load tests (run with pkexec). `click X,Y [sleepS] [mX,Y] …` clicks or moves a synthetic pointer at logical coordinates on a 1600×1000 layout, for testing the shell. |

No Omarchy package is left except `omarchy-keyring`, which goes with its repository. That repository is still listed (last) in `pacman.conf` and supplies a few third-party packages Arch does not: the fingerprint library, `tzupdate`, the boot-menu tools. The icon theme is Arch's Adwaita (`gsettings set org.gnome.desktop.interface icon-theme Adwaita`).

## Display

| File | What |
|---|---|
| `.config/hypr/display.lua` | The display setup. The panel's scale cycles through 1, 1.5, 1.8 and 2 on Fn+F8, shows the new scale in the on-screen pop-up, and is kept in `~/.local/state/edp-scale`. `edp_override_scale(n)` sets a temporary scale that is not saved; called with nothing, or on the next Fn+F8, the saved scale returns. eDP-1 always in HDR, 10-bit. Brightness is the SDR white level: nits = `edp_sdr_white` × level ^ `edp_brightness_gamma`. `edp_sdr_white`, the nits at 100%, is the panel's own full-screen maximum (the max frame-average luminance in its EDID's HDR metadata, 702.5 nits here; 600 if the EDID can't be read); the exponent is 2.2. With the lid closed and another monitor attached the panel is off (`edp_lid`), and it comes back when the lid opens or the last other monitor goes. |
| `.local/bin/ambient-display` + service | Owns brightness and white point. Follows the light sensor, learns from manual changes, takes requests on `$XDG_RUNTIME_DIR/ambient-display.sock`. Raises a screen left below 15% on wake from suspend. Learns that the panel went on, off or away from Hyprland's monitor events and from `hypridle` (`echo screen` to the socket), and otherwise looks once a minute. |
| `.local/bin/hdr-brightness` | Brightness keys. Asks `ambient-display`; sets the level itself if the daemon is down; does nothing for other monitors. |
| `.local/bin/white-point` | Shift + brightness keys: `warmer`, `cooler`, or a kelvin value. |
| `.local/bin/white-point-ctm` | Holds Hyprland's colour matrix; run by `ambient-display`. |
| `.local/bin/brightness-why` | Explains the current brightness and the evidence behind it. |
| `.config/hypr/hypridle.conf` | Display off at 8 min, suspend at 10; both skipped in stay-awake. Locks before every suspend with the lock screen drawn black (`qs ipc call lock blank`), holds the suspend until the lock is up, and shows the password box on wake (`lock reveal`, or any key or click). |
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

## Desktop

| File | What |
|---|---|
| `.config/quickshell/` | Our own shell (Quickshell), run by `shell.service`; after an edit, `systemctl --user restart shell`. `shell.qml` lists the parts and `Bar.qml` is the bar's fixed layout. Bar: workspaces that have windows, shown only when there is more than one (`Workspaces.qml`); a blank slot that shows the tray icons, Bluetooth and stay-awake while the pointer is over it; stay-awake stays visible while it is on (`Tray.qml`); weather; Wi-Fi; battery; clock. Panels open from their icon (`Panel.qml`, one at a time; a click anywhere else or Escape closes them). The bar sits on the layer beneath windows: on the top layer, Hyprland hands focus to the last window, hidden console included, whenever something closes with the pointer over it: battery level, watts and time left; Wi-Fi on/off, networks, password to join; Bluetooth on/off, devices, connect, pair. Right-click a saved network or a paired device, then click it again, to forget it. Both lists scroll (`PanelList.qml`). `Osd.qml` is the volume, brightness, white point and keyboard backlight pop-up; `Audio.qml` the volume and mute keys; `Menu.qml` the app launcher, which also lists sleep, hibernate, log out, restart and shut down, each found by its synonyms too (suspend, reboot, power off); `Polkit.qml` the permission prompt; `Lock.qml` the lock screen (password or fingerprint, PAM files in `pam/`), which locks again if the shell restarts while locked; `Wallpaper.qml` the wallpaper (`/usr/local/share/expertbook-tweaks/wallpaper.jpg`, the Mac OS X Tiger image, which `install.sh --system` fetches). `Theme.qml` holds colours, fonts and sizes. From scripts: `qs ipc call osd pop <icon> <percent> <text>`, `qs ipc call lock lock`, `qs ipc call menu open`. |
| `.config/systemd/user/shell.service` | Runs the shell in the graphical session and restarts it if it fails. |
| `.local/bin/terminal-here` | Super+Return: a terminal in the directory of the focused terminal's shell. |
| `.local/bin/keyboard-backlight` | `up`, `down`, `cycle` for the keyboard backlight key. |
| `.bashrc` | A plain shell: `~/.local/bin` on `PATH`, `vim` as the editor, history, completion, a bare prompt. Omarchy's shell setup is not loaded. |
| `.config/foot/foot.ini` | The terminal: DejaVu Sans Mono Nerd Font, the Tiger light colours, no bell. |
| `.config/hypr/hyprland.lua` | Our own Hyprland config; loads the files below. Omarchy's Hyprland defaults are not loaded. |
| `.config/hypr/keys.lua` | Every keybinding: terminal, browser, the menu key, Fn+F8 to cycle the display scale, close window, Super + left-drag to move a window, full screen, workspaces 1-3, copy and paste, volume, brightness, white point, keyboard backlight, lid switch, Fn+F9 (key code 192) to dictate to Claude. |
| `.config/hypr/console.lua` | The Quake console: a tap of Right Alt toggles it (held for 200 ms, Right Alt is hold-to-talk); sized to half the screen; stray windows opened into it move to the workspace. `console_dictate()` shows the console and sends it Alt+K, which `~/.claude/keybindings.json` (not in this repo) binds to voice dictation in place of Space, with `"voice": { "enabled": true, "mode": "tap" }` in `~/.claude/settings.json`: one press starts recording, the next sends. Holding Right Alt does the same on press and on release, for hold-to-talk. |
| `.config/hypr/inputs.lua` | US layout, Caps Lock is Ctrl, both Shifts toggle Caps Lock, natural scrolling, key repeat. The touchpad uses a custom libinput acceleration curve shaped like a MacBook's: pointer gain is `gain` x (finger speed in mm/s)^`exponent` pixels per mm, with no plateau. |
| `.config/hypr/look.lua` | Gaps, rounding, shadows, animations; no window borders; VRR for fullscreen windows; no second SDR copy of each HDR frame unless something is capturing the screen. |
| `.config/hypr/windows.lua` | Window and layer rules: dialogs float, Steam's main window tiles and closing Steam's windows runs `steam-quit-when-closed`, GeForce NOW's tags for wheel scrolling and touch. `cycle_window_mode()` steps the focused window through tiled, floating and full screen. |
| `.config/hypr/env.lua`, `helpers.lua`, `start.lua` | Session environment; the `o.bind` / `o.window` helpers; what starts at login. |
| `.local/bin/attention`, `system/etc/udev/rules.d/70-capslock-led.rules` | The Caps Lock light, solid, means an agent needs input. `attention on\|off [reason]`, keyed by the calling Claude Code process; hooks in `~/.claude/settings.json` raise it for permission prompts and questions and clear it when answered. |
| `.local/bin/steam-quit-when-closed` | Shuts Steam down a few seconds after its last window closes, unless a game is running, Steam has only just started, or TV mode is on. Steam never sits in the tray. |
| `.config/fontconfig/conf.d/61-default-sans.conf` | DejaVu Sans as the default sans-serif; it is also the shell's and the GTK interface font. |

## System settings

Kept from Omarchy's settings package under our own file names (MIT, see `LICENSE.omarchy`).

| File under `system/` | What |
|---|---|
| `etc/mkinitcpio.conf.d/expertbook.conf` | Boot image hooks: splash, disk unlock, snapshot boot, resume from hibernation; Thunderbolt early. |
| `etc/limine-entry-tool.d/expertbook.conf` | Boot menu: one unified kernel image, quiet boot, six snapshot entries. Rebuild with `limine-mkinitcpio`. |
| `home/.local/bin/update` | The way to update: lists what is pending, takes a snapshot, runs `pacman -Syu`, rebuilds and reinstalls Hyprland with our patches if the update replaced it, checks the Hyprland config against a new Hyprland, restarts the shell on a new Quickshell, and ends with a summary of anything needing attention (failed rebuild, config files to merge, reboot or re-login). `update --check` only reports. |
| `etc/pacman.d/hooks/expertbook-patched.hook`, `usr/local/share/expertbook-tweaks/patched-check` | After any update that installs Hyprland, says in pacman's output if it is now the stock build (ours ends in `.1`) and which build script to run. |
| `etc/pacman.d/hooks/expertbook-limine-deploy.hook` | Copies a new Limine bootloader to the boot partition when the `limine` package updates. |
| `etc/plymouth/plymouthd.conf`, `usr/share/plymouth/themes/expertbook/` | The boot screen: black, with a dark box and one dot per character while the disk password is being typed. No logo, spinner or text. Rebuild the boot image after changing it (`limine-mkinitcpio`). |
| `etc/systemd/logind.conf.d/expertbook.conf` | The power key and the lid suspend, locking first, and hibernate from sleep if the battery falls to about 5% (`suspend-then-hibernate`; the idle timer and the menu's Sleep do the same; the image goes to `/swap/swapfile`); the firmware ignores taps shorter than about a second; 15 s for the lock to draw before sleep. |
| `etc/systemd/system.conf.d/`, `user.conf.d/`, `system/user@.service.d/` | 5 s stop timeouts; high open-file limits (games). |
| `etc/systemd/oomd.conf.d/`, `etc/systemd/user/app.slice.d/` | Apps under sustained memory pressure are killed. |
| `etc/systemd/user/wayland-wm@hyprland.desktop.service.d/` | Logging out stops the compositor first and the rest after. |
| `etc/systemd/user/bt-agent.service` | Pairing agent the Bluetooth panel relies on. |
| `etc/systemd/zram-generator.conf.d/`, `etc/sysctl.d/90-expertbook.conf`, `etc/udev/rules.d/60-expertbook-io-scheduler.rules` | Compressed RAM swap the size of RAM with matching memory tuning; BBR; more file watchers; the kyber disk scheduler. |
| `usr/lib/systemd/system-sleep/unmount-fuse` | Unmounts GVFS mounts before sleep and restarts GVFS after. |
| `usr/lib/systemd/system-sleep/firmware-state` | After any wake, puts back what the firmware resets when hibernation powers the laptop off: re-attaches the speaker and microphone mute lights to their triggers (the firmware lights both while the kernel still believes they are off), and runs `lightbar-off` and `fn-keys-on` again. |
| `etc/systemd/resolved.conf.d/`, `etc/NetworkManager/conf.d/expertbook-wifi-powersave.conf`, `etc/modprobe.d/expertbook-usb-autosuspend.conf` | mDNS left to Avahi; Wi-Fi power save off; USB autosuspend off. |
| `etc/systemd/system/*pcr*`, `*tpm2*`, `*binfmt*`, `plocate-updatedb.service.d/` | Boot services that would report failure on this machine; file index only on mains and skipping snapshots. |
| `etc/xdg/mimeapps.list`, `etc/gnupg/dirmngr.conf` | Default apps for folders, images and PDFs; key servers. |

| File under `home/` | What |
|---|---|
| `.inputrc`, `system/etc/modprobe.d/expertbook-no-beep.conf` | No bell from the shell and no PC speaker. With desktop event sounds off (`gsettings set org.gnome.desktop.sound event-sounds false`, `org.gnome.desktop.wm.preferences audible-bell false`) and `[bell] system=no` in `foot.ini`, the system itself makes no alert sounds; apps keep their own settings. |
| `.bash_profile`, `.hushlogin`, `system/etc/systemd/system/getty@tty1.service.d/autologin.conf` | Login: the first console logs in by itself (the disk password is the gate) and its login shell starts Hyprland under uwsm. No login manager; logging out starts a fresh session. |
| `.config/uwsm/env` | Session environment: `~/.local/bin` on `PATH` (Claude Code lives there, from Anthropic's installer, and updates itself), `vim`, `foot`. |

## Hardware

| File | What |
|---|---|
| `.local/bin/sdw-clash-recover` + service | Suspends and resumes the speaker sink after a SoundWire bus clash on link 2, which otherwise leaves the woofers silent. |
| `system/etc/modprobe.d/expertbook-fnlock.conf` | Starts each boot with Fn-lock in the other state from the driver's default (`asus_wmi fnlock_default=N`), so Fn+Esc is not needed after every boot. Rebuild the boot image after changing it (`limine-mkinitcpio`). |
| `system/usr/local/share/expertbook-tweaks/lightbar-off`, `system/etc/systemd/system/lightbar-off.service` | Early in boot, switches off the firmware lighting effects of the light bar under the screen (ASUS WMI device 0x00050028, argument 0x80, through `asus-nb-wmi`'s debugfs). The firmware turns them back on at every power-on, so the bar still pulses until this runs. |
| `system/usr/local/share/expertbook-tweaks/fn-keys-on`, `system/etc/systemd/system/fn-keys-on.service`, `system/etc/udev/rules.d/70-expertbook-fn-keys.rules`, `.local/bin/fn-keys` + service, `.local/bin/stay-awake` | Fn+F10 and Fn+F11. The firmware drops both keys unless its hotkey flags are set (ASUS WMI device 0x00100046, argument 0x600, written early in boot). They then arrive on the "Asus WMI hotkeys" input device as an unknown key with scan codes 0x19 and 0x1A; the udev rule lets the logged-in user read that device, and `fn-keys` runs `cycle_window_mode()` for Fn+F10 and `stay-awake toggle` for Fn+F11. `stay-awake toggle\|on\|off` sets the flag, refreshes the bar icon and shows the pop-up. |
| `system/usr/local/share/expertbook-tweaks/psr-after-desktop` + service | Keeps the panel's self-refresh off from early boot, and turns it on the moment the desktop's Hyprland has switched the panel to 10-bit BT.2020 (`i915_edp_psr_debug`, watching the kernel's display state). After that mode switch the panel shows the HDR picture as if it were SDR (banded, green-tinged) until self-refresh is next enabled or left; turning it on right then corrects it before the wallpaper appears. |
| `system/usr/local/bin/rapl-sync` + service | Copies the firmware's MMIO PL1/PL2 onto the MSR limits; without it every profile sustains 15 W. |
| `system/etc/modules-load.d/uinput.conf` | Steam Input needs `uinput` loaded to make virtual controllers. |
| `system/etc/udev/hwdb.d/70-pocketpad.hwdb` | Button names for the Retroid Pocket Nova as a Bluetooth gamepad (PocketPad). |
| `system/etc/systemd/system/ollama.service.d/override.conf` | Ollama on the iGPU. |
| `.local/share/fp-shim/fp-storage.py` | Lists or clears fingerprint templates on the FocalTech reader's chip. Enrol with `fprintd-enroll`. |
| `system/etc/pam.d/login`, `system/usr/local/share/expertbook-tweaks/lid-closed` | Fingerprint at a console login, skipped while the lid is closed (`lid-closed`, which `install.sh --system` also puts into the sudo and polkit files). The stock file is kept beside it as `login.before-fingerprint`. |

## Games and TV

| File | What |
|---|---|
| `.local/bin/game`, `.config/MangoHud/MangoHud.conf` | Steam launch option `game %command%`: native Wayland window, MangoHud hidden until Right Shift + F12. |
| `.local/share/flatpak/overrides/com.nvidia.geforcenow` | GeForce NOW uses the Flatpak runtime's SDL (`SDL_DYNAMIC_API`) in place of its bundled one, which was built without Xcursor and turns the game's cursors into two-colour blobs. |
| `.local/bin/geforcenow`, `.local/share/applications/com.nvidia.geforcenow.desktop` | The one GeForce NOW menu entry: HDR, 120 FPS, real pixels. The launcher updates the Flatpak, switches the panel to scale 1 until the client exits (as a native Wayland window the client draws at the window's logical size, so only scale 1 is sharp), and starts the client binary directly with the corrected EDID (`GAMESCOPE_PATCHED_EDID_FILE`) and `geforcenow-hdr/redirect.so`. NVIDIA's own start script is skipped because it clears `LD_PRELOAD`. |
| `.local/bin/tv-mode` + service, `.config/hypr/tv-mode.lua` | A 1080p TV plus power turns the laptop into a Big Picture console. Sound goes to the TV unmuted at 100%, so the TV's remote is the volume control; the speakers keep their own level for afterwards. `tv-mode sim …` runs it against a simulator. |

## Not obvious

- Changing focus from a Lua key handler while that key is still being processed leaves XWayland believing the key is held (it arrives in the new window's list of pressed keys and is never released there). X11 apps then see every key with that modifier: this is what broke typing in GeForce NOW.
- A USB-C power plug or unplug sends the same "unknown key" (code 240) as Fn+F10 and Fn+F11, so nothing is bound to that key in Hyprland; they differ only in scan code (charger 0x77).
- KMS applies the colour matrix to the encoded signal, which is wrong for PQ; `02-hdr-conversion` is why kelvin values are true.
- Only one client may hold the colour matrix. hyprsunset must not run; `ambient-display` kills it if it does.
- Hyprland draws window borders at a fixed 80 nits whatever the SDR white level, hence no borders.
- Subpixel antialiasing on transparent layers overshoots white in HDR, hence greyscale (fontconfig, and `QSG_DISTANCEFIELD_ANTIALIASING` for Qt Quick).
- An official Hyprland update replaces the patched build.
- HDR is relative here: a game's white is its declared reference white (203 nits when it declares none), drawn at the desktop's white. Set a game's paper white to 203. Chromium declares the advertised white as its reference, so it is scaled by 1.
- Each read of the light sensor blocks about a second.
- Stock Hyprland rewrites the keyboard LEDs on every key event, which flickers the attention light; `03-leds-only-on-change` stops that, and `attention` still re-asserts the light in case the Caps Lock state changes.
- Hyprland's Lua key event carries xkb keycodes (evdev + 8).
- The Tiger wallpaper is Apple's artwork: fetched by `install.sh`, not committed.

## Omarchy is frozen

Packages come from the Arch mirrors in `system/etc/pacman.d/mirrorlist`, not Omarchy's delayed mirror; Omarchy's own repo is still configured for its kernel and a few other packages. `install.sh --system` lists Omarchy's repository last in `/etc/pacman.conf`, so anything Arch also packages (Quickshell) comes from Arch. Update with `update`.

## Packages added to Omarchy

`libfprint-git` `fprintd` · `ollama` `ollama-vulkan` · `hypridle` · `socat` · `mangohud` · `ttf-dejavu` `ttf-dejavu-nerd` · `cmake` `glaze` `hyprland-protocols` `hyprwayland-scanner` (to build Hyprland).

Removed from Omarchy: `herdr`, the titlebar plugin, the input-method framework (`fcitx5`), the video wallpaper engine (`owe`), Omarchy's Neovim setup and Neovim, Docker, printing, Moonlight, the capture tools (screen recorder, colour picker, OCR, QR), the virtual-webcam module, and the command-line extras its shell setup used (`eza`, `bat`, `zoxide`, `fzf`, `starship`, `tmux`, `lazygit`, `tldr`, `yt-dlp`, `fastfetch`). `SUPER + CTRL + RETURN` no longer does anything.

## License

MIT; see `LICENSE`. Files adopted from Omarchy are Copyright (c) David Heinemeier Hansson, MIT; see `LICENSE.omarchy`.
