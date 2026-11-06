# expertbook-tweaks

Personal tweaks for an ASUS ExpertBook Ultra (B9406CAA) running Omarchy, on top
of the community fixes in [asus-expertbook-linux](https://github.com/burakgon/asus-expertbook-linux),
used unmodified from upstream `main`.

Files here are the real copies; `./install.sh` symlinks them into place, so
editing either path edits the tracked file. `./install.sh --system` also copies
`system/` into `/` via pkexec (those can't be symlinks into a home directory).

## What's here

| Path | Linked to | Purpose |
|---|---|---|
| `hypr/hdr.lua` | loaded by `~/.config/hypr/monitors.lua` | Internal OLED in always-on HDR, 10-bit (`edp_hdr_monitor()`), border dimming; software cursor, because the hardware cursor plane skips colour management and renders at peak brightness in HDR. `monitors.lua` itself stays a real file because Omarchy edits its scale lines with `sed -i`, which would replace a symlink. |
| `hypr/input.lua` | `~/.config/hypr/` | Caps Lock is Ctrl (`ctrl:nocaps`; the keyboard has no Right Ctrl), no Compose key; both Shifts toggle Caps Lock. Natural touchpad scrolling. |
| `hypr/bindings.lua` | `~/.config/hypr/` | Brightness keys (plain/Alt) call `hdr-brightness`; Shift + them calls `white-point`. F14 (code:192) is deliberately unbound: the ASUS firmware sends it on every USB-C power plug/unplug (asus_wmi 0x77), not just Fn+F9. |
| `hypr/hypridle.conf` | `~/.config/hypr/` | Display off after 8 min idle, suspend (Omarchy locks on suspend) at 10 min; both skipped in Omarchy stay-awake. On wake from suspend, `bin/brightness-wake-floor` raises the screen to at least 5% so the lock screen is visible. Needs `pacman -S hypridle`. Omarchy shell.json (not in repo) has `idle.screensaver = 0`, `idle.lock = 0`. |
| `bin/hdr-brightness` | `~/.local/bin/` | In HDR the panel ignores its backlight, so brightness is Hyprland's `sdrbrightness`, saved to `~/.local/state/hdr-brightness` and reapplied by `monitors.lua`. HDR off or another monitor: passes through to `omarchy-brightness-display`. No step prints the current percent. |
| `bin/ambient-display`, `systemd-user/ambient-display.service`, `bin/white-point` | `~/.local/bin/`, `~/.config/systemd/user/` | Ambient-light brightness **and** white point in one daemon (replaced `hdr-auto-brightness` and `ambient-white`, 2026-11-06). One sensor thread reads lux ~1 Hz and colour every third read (each ISH read blocks ~1 s). Both controllers work the same way: a model predicts from the sensors, the screen glides there calmly, and manual changes are learned once left alone for 4 s. **Brightness** (through `hdr-brightness`, works in HDR): learned monotonic lux→nits points on log lux (nits so the curve survives changing `edp_sdr_white`, published by `hdr.lua` to `~/.local/state/hdr-sdr-white`); lux smoothed 7.5 s up / 30 s down, 3% deadband, 1% steps every 0.7 s up / 1 s down; never auto-sets below 5% (below that, including 0, is manual-only and never learned). **White point** (through hyprsunset, 100 K grid): lit → partway (35% in mireds) toward the room's colour, 5000–6600 K; dark (the sensor's fixed 4500 K "can't measure" reading for 15 s, colour lost around 7–37 lux) → fades on log lux from the last lit value at the lux where colour was lost to 4500 K at ≤ 3 lux; plus learned corrections. Shift + brightness keys run `white-point` (dim = warmer, bright = cooler, 200 K, 2500–6600 K, OSD), which sets hyprsunset and writes `~/.local/state/white-point.manual`; the daemon holds it and learns the difference from the model (mireds) at the room's lux. Corrections interpolate on log lux and fade back to the plain model over a decade past the outermost points. Ramps ≤ 2.5 mired/s, colour and lux smoothed 30 s, hysteresis (one 100 K step once 150 K off; snaps onto endpoints). 6600 K is hyprsunset's ~identity. Re-sends every 30 s (hyprsunset re-applies its profile daily). State: `~/.local/state/ambient-display.json` (`brightness`, `white_offsets`, `dark_fade`; delete a key to forget it). SIGUSR1 = adopt the current brightness without learning it. Logs: `journalctl --user -u ambient-display`. |
| `bin/brightness-wake-floor` | `~/.local/bin/` | Called by `hypridle.conf` on wake: if brightness is below 5% (`FLOOR`), sets 5% and sends `ambient-display` SIGUSR1 so it adopts the new level without learning it, then fades to its usual level for the room. |
| `fontconfig/60-grayscale-antialias.conf`, `hl.env("QSG_DISTANCEFIELD_ANTIALIASING", "gray")` in `hypr/hdr.lua` | `~/.config/fontconfig/conf.d/` | Greyscale text antialiasing instead of subpixel. The Omarchy 4.5 bar draws text and icons on a transparent layer, where subpixel AA's per-channel coverage ends up with RGB above the single alpha (correct would be alpha = max channel coverage). Blending that overshoots 1.0: clamped invisibly in an 8-bit (unorm8) SDR buffer, but kept in Hyprland's higher-precision HDR blending and shown brighter than white (stray bright pixels on icon edges). Qt Quick ignores fontconfig here, hence the env var as well. |
| `hypr/hyprsunset.conf` | `~/.config/hypr/` | Neutral startup profile for hyprsunset; `ambient-display` drives it. (A sunset/sunrise schedule preceded it: git history `nightlight-sun`.) |
| `omarchy-plugins/mtklein.nightlight/`, `omarchy/omarchy-menu.jsonc` | `~/.config/omarchy/plugins/`, `~/.config/omarchy/extensions/` | Night light toggle for `ambient-display`: a clone of Omarchy's night light service (`omarchy plugin clone omarchy.nightlight`) with 4500 K on / 6600 K off, "on" meaning below 5000 K (not Omarchy's 6000, since lit rooms go down to 5000 K), a 30 s re-read so the bar follows the daemon, and a toggle that writes `~/.local/state/ambient-white.override` (`night`/`day`), honoured until the room next changes dark ↔ lit or the white point keys are used. The menu file points Trigger > Toggle > Nightlight at the service. `omarchy toggle nightlight` on the command line bypasses all this (4000 K). |
| `bin/sdw-clash-recover`, `systemd-user/sdw-clash-recover.service` | `~/.local/bin/`, `~/.config/systemd/user/` | Brings the bass back after a SoundWire glitch. The CS35L56 woofer amps are on link 2; a sporadic "Bus clash" / "Parity error" there (a few a day, seen mid-playback with nothing else happening) can leave them silent while the tweeters keep playing. The kernel's Cadence driver only logs these and never resyncs, so this follows the kernel log and suspends/resumes the speaker sink, which re-prepares the stream (sub-second blip). Recoveries: `journalctl --user -u sdw-clash-recover`. |
| `bin/game-touchpad-guard`, `systemd-user/game-touchpad-guard.service` | `~/.local/bin/`, `~/.config/systemd/user/` | Turns the touchpad off (silently, not persisted) while a game in its `GAMES` list (window class or title; FF Resonance for now) is focused, and back on when focus leaves, so stray touches don't wake the mouse cursor. A touchpad turned off with `omarchy-toggle-touchpad` stays off. Follows Hyprland's event socket. |
| `bin/hdr-monitor-state` | `~/.local/bin/` | `omarchy-monitor-state` with the brightness line from `hdr-brightness`. |
| `omarchy-plugins/mtklein.monitor/` | `~/.config/omarchy/plugins/` | Clone of the bar's Display panel; `Panel.qml` reads/sets brightness through the two scripts above. Doesn't receive upstream `omarchy.monitor` updates. |
| `fingerprint/omarchy-hw-fingerprint` | `~/.local/share/fp-shim/` | Detection shim: Omarchy misses the FocalTech FT9349 (`2808:a97a`), which libfprint supports. Run setup as `PATH=~/.local/share/fp-shim:$PATH omarchy-setup-security-fingerprint`. |
| `fingerprint/fp-storage.py` | `~/.local/share/fp-shim/` | List (`sudo python3 fp-storage.py`) or wipe (`--clear`) templates stored on the sensor chip. Stale Windows Hello templates there made every verify fail. |
| `wluma/config.toml` | `~/.config/wluma/` | Ambient-light screen brightness, keyboard excluded. **Unused** (wluma isn't installed): it drives the backlight, which does nothing in HDR; `ambient-display` replaces it. |
| `system/usr/local/bin/rapl-sync`, `system/etc/systemd/system/rapl-sync.service` | `/usr/local/bin/`, `/etc/systemd/system/` | Copies the firmware's (MMIO) PL1/PL2 onto the MSR RAPL limits every 2 s, as Windows does. The BIOS leaves MSR PL1 at 15 W and the CPU obeys the lower copy, so without this every profile sustains only 15 W. |
| `system/etc/systemd/system/ollama.service.d/override.conf` | `/etc/systemd/system/ollama.service.d/` | Ollama on the Arc B390 iGPU, flash attention, q8_0 KV cache, 32k context. |
| `system/etc/udev/hwdb.d/70-pocketpad.hwdb` | `/etc/udev/hwdb.d/` | Button names for [PocketPad](https://github.com/Dathaze20/PocketPad), the Android app that makes the Retroid Pocket Nova a Bluetooth HID gamepad (`0005:001D:1200`, "RPN"). It declares 16 anonymous buttons, so the kernel names them in order and SDL's automatic mapping (Steam, native games) put X/Y, bumpers, Select/Start and stick clicks on the wrong functions; this renames them to the standard codes. Android keeps Home for itself. Connect from the Nova (PocketPad → Settings → Connect to a paired device). |
| `system/etc/modules-load.d/uinput.conf` | `/etc/modules-load.d/` | Loads `uinput` at boot. steam-devices grants `/dev/uinput` access (uaccess) only once the module is loaded; without it Steam Input can't create virtual controllers, so Proton games get no input from controllers Steam itself reads fine. |

## Known quirks

- `sdrbrightness` doesn't reach window borders, so `monitors.lua` dims the theme's border colours by the same factor (linear light), re-reading the theme each time.

## License

MIT; see `LICENSE`.

## Third-party code

`omarchy-plugins/mtklein.monitor/` is a modified copy of Omarchy's `omarchy.monitor`
plugin, Copyright (c) David Heinemeier Hansson, MIT licensed; see
`omarchy-plugins/mtklein.monitor/LICENSE.omarchy`.

## Packages added on top of Omarchy

Installed by us (2026-11-04):

| Package | Why |
|---|---|
| `libfprint-git`, `fprintd` | Fingerprint reader (via `omarchy-setup-security-fingerprint` with the shim). |
| `ollama`, `ollama-vulkan` | Local LLMs on the Arc iGPU (see the Ollama override). |
| `cmake`, `glaze`, `hyprland-protocols`, `hyprwayland-scanner` | Build deps for `hyprland-patched/` (installed `--asdeps`). |
| `hyprland` `<ver>-<rel>.1` | Patched build from `hyprland-patched/` (replaces the official package until the next official update). |

Installed by `asus-expertbook-linux` modules: `thermald`, `dkms`, `v4l2loopback-dkms`, `obs-studio`, `libinput-tools`, `fwupd`, `meson`, `ninja`, plus its files under `/usr/local` and `/etc` (see `./patch.sh status`).

## Tools

- `tools/power-profile-loadtest.sh`: 60 s all-core load in each power profile, reporting package power. Run on AC and on battery to compare (`pkexec bash tools/power-profile-loadtest.sh`).
- `tools/power-trace.sh`: 50 s load in Performance, printing power, temperature and PL1 every 5 s.
