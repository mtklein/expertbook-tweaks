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
| `hypr/bindings.lua` | `~/.config/hypr/` | Brightness keys (plain/Shift/Alt) call `hdr-brightness`. F14 (code:192) is deliberately unbound: the ASUS firmware sends it on every USB-C power plug/unplug (asus_wmi 0x77), not just Fn+F9. |
| `hypr/hypridle.conf` | `~/.config/hypr/` | Display off after 8 min idle, suspend (Omarchy locks on suspend) at 10 min; both skipped in Omarchy stay-awake. Needs `pacman -S hypridle`. Omarchy shell.json (not in repo) has `idle.screensaver = 0`, `idle.lock = 0`. |
| `bin/hdr-brightness` | `~/.local/bin/` | In HDR the panel ignores its backlight, so brightness is Hyprland's `sdrbrightness`, saved to `~/.local/state/hdr-brightness` and reapplied by `monitors.lua`. HDR off or another monitor: passes through to `omarchy-brightness-display`. No step prints the current percent. |
| `bin/hdr-auto-brightness`, `systemd-user/hdr-auto-brightness.service` | `~/.local/bin/`, `~/.config/systemd/user/` | Ambient-light screen brightness through `hdr-brightness`. Learns like wluma (manual changes become monotonic lux→nits points, log-lux interpolation; nits so the curve survives changing `edp_sdr_white`, which `hdr.lua` publishes to `~/.local/state/hdr-sdr-white`) and moves like macOS (smoothed lux, faster up than down, 1% fades, deadband). Learned curve: `~/.local/state/hdr-auto-brightness.json` (delete to reset). Pause with `systemctl --user stop hdr-auto-brightness`. |
| `bin/hdr-monitor-state` | `~/.local/bin/` | `omarchy-monitor-state` with the brightness line from `hdr-brightness`. |
| `omarchy-plugins/mtklein.monitor/` | `~/.config/omarchy/plugins/` | Clone of the bar's Display panel; `Panel.qml` reads/sets brightness through the two scripts above. Doesn't receive upstream `omarchy.monitor` updates. |
| `fingerprint/omarchy-hw-fingerprint` | `~/.local/share/fp-shim/` | Detection shim: Omarchy misses the FocalTech FT9349 (`2808:a97a`), which libfprint supports. Run setup as `PATH=~/.local/share/fp-shim:$PATH omarchy-setup-security-fingerprint`. |
| `fingerprint/fp-storage.py` | `~/.local/share/fp-shim/` | List (`sudo python3 fp-storage.py`) or wipe (`--clear`) templates stored on the sensor chip. Stale Windows Hello templates there made every verify fail. |
| `wluma/config.toml` | `~/.config/wluma/` | Ambient-light screen brightness, keyboard excluded. **Unused** (wluma isn't installed): it drives the backlight, which does nothing in HDR; `hdr-auto-brightness` replaces it. |
| `system/usr/local/bin/rapl-sync`, `system/etc/systemd/system/rapl-sync.service` | `/usr/local/bin/`, `/etc/systemd/system/` | Copies the firmware's (MMIO) PL1/PL2 onto the MSR RAPL limits every 2 s, as Windows does. The BIOS leaves MSR PL1 at 15 W and the CPU obeys the lower copy, so without this every profile sustains only 15 W. |
| `system/etc/systemd/system/ollama.service.d/override.conf` | `/etc/systemd/system/ollama.service.d/` | Ollama on the Arc B390 iGPU, flash attention, q8_0 KV cache, 32k context. |

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
