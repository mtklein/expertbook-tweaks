#!/usr/bin/env python3
# List (default) or wipe (--clear) the templates stored on a match-on-chip
# fingerprint sensor. Run as root; stops fprintd first so it can claim the USB device.
import subprocess, sys
import gi
gi.require_version("FPrint", "2.0")
from gi.repository import FPrint

subprocess.run(["systemctl", "stop", "fprintd"], check=False)

ctx = FPrint.Context()
ctx.enumerate()
devs = ctx.get_devices()
if not devs:
    sys.exit("no fingerprint device found")
dev = devs[0]
print(f"device: {dev.get_name()} (driver {dev.get_driver()})")
dev.open_sync()
try:
    prints = dev.list_prints_sync()
    print(f"{len(prints)} template(s) stored on the sensor:")
    for p in prints:
        print(f"  user={p.get_username()!r} finger={p.get_finger().value_nick} "
              f"desc={p.get_description()!r}")
    if "--clear" in sys.argv:
        dev.clear_storage_sync()
        print("sensor storage cleared")
finally:
    dev.close_sync()
