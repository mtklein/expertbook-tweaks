# expertbook-tweaks

Personal tweaks for an ASUS ExpertBook Ultra (B9406CAA) running Omarchy, on top
of the community fixes in `~/asus-expertbook-linux` (whose own changes live on
its `mute-led-invert` branch).

Files here are the real copies; `./install.sh` symlinks them into place, so
editing either path edits the tracked file. `./install.sh --system` also copies
`system/` into `/` via pkexec (those can't be symlinks into a home directory).

## What's here

| Path | Linked to | Purpose |
|---|---|---|
| `hypr/hdr.lua` | loaded by `~/.config/hypr/monitors.lua` | Internal OLED in always-on HDR, 10-bit (`edp_hdr_monitor()`), border dimming; software cursor, because the hardware cursor plane skips colour management and renders at peak brightness in HDR. `monitors.lua` itself stays a real file because Omarchy edits its scale lines with `sed -i`, which would replace a symlink. |
| `hypr/input.lua` | `~/.config/hypr/` | Caps Lock is Ctrl (`ctrl:nocaps`; the keyboard has no Right Ctrl), no Compose key; both Shifts toggle Caps Lock. Natural touchpad scrolling. |
| `hypr/bindings.lua` | `~/.config/hypr/` | Brightness keys (plain/Shift/Alt) call `hdr-brightness`. |
| `bin/hdr-brightness` | `~/.local/bin/` | In HDR the panel ignores its backlight, so brightness is Hyprland's `sdrbrightness`, saved to `~/.local/state/hdr-brightness` and reapplied by `monitors.lua`. HDR off or another monitor: passes through to `omarchy-brightness-display`. No step prints the current percent. |
| `bin/hdr-auto-brightness`, `systemd-user/hdr-auto-brightness.service` | `~/.local/bin/`, `~/.config/systemd/user/` | Ambient-light screen brightness through `hdr-brightness`. Learns like wluma (manual changes become monotonic lux→brightness points, log-lux interpolation) and moves like macOS (smoothed lux, faster up than down, 1% fades, deadband). Learned curve: `~/.local/state/hdr-auto-brightness.json` (delete to reset). Pause with `systemctl --user stop hdr-auto-brightness`. |
| `bin/hdr-monitor-state` | `~/.local/bin/` | `omarchy-monitor-state` with the brightness line from `hdr-brightness`. |
| `omarchy-plugins/mtklein.monitor/` | `~/.config/omarchy/plugins/` | Clone of the bar's Display panel; `Panel.qml` reads/sets brightness through the two scripts above. Doesn't receive upstream `omarchy.monitor` updates. |
| `fingerprint/omarchy-hw-fingerprint` | `~/.local/share/fp-shim/` | Detection shim: Omarchy misses the FocalTech FT9349 (`2808:a97a`), which libfprint supports. Run setup as `PATH=~/.local/share/fp-shim:$PATH omarchy-setup-security-fingerprint`. |
| `fingerprint/fp-storage.py` | `~/.local/share/fp-shim/` | List (`sudo python3 fp-storage.py`) or wipe (`--clear`) templates stored on the sensor chip. Stale Windows Hello templates there made every verify fail. |
| `systemd-user/expertbook-mute-leds.service.d/invert.conf` | `~/.config/systemd/user/` | `MUTE_LED_INVERT=1`: mute LEDs lit while audio is live. |
| `wluma/config.toml` | `~/.config/wluma/` | Ambient-light screen brightness, keyboard excluded. **Unused** (wluma isn't installed): it drives the backlight, which does nothing in HDR; `hdr-auto-brightness` replaces it. |
| `system/etc/udev/rules.d/90-b9406-mute-led-userspace.rules` | `/etc/udev/rules.d/` | Detaches the speaker mute LED from the kernel trigger so the sync service can invert it. |
| `system/usr/local/bin/rapl-sync`, `system/etc/systemd/system/rapl-sync.service` | `/usr/local/bin/`, `/etc/systemd/system/` | Copies the firmware's (MMIO) PL1/PL2 onto the MSR RAPL limits every 2 s, as Windows does. The BIOS leaves MSR PL1 at 15 W and the CPU obeys the lower copy, so without this every profile sustains only 15 W. |
| `system/etc/systemd/system/ollama.service.d/override.conf` | `/etc/systemd/system/ollama.service.d/` | Ollama on the Arc B390 iGPU, flash attention, q8_0 KV cache, 32k context. |

## Known quirks

- `sdrbrightness` doesn't reach window borders, so `monitors.lua` dims the theme's border colours by the same factor (linear light), re-reading the theme each time.
- Before login, the mute LEDs keep whatever state they were last in.
