# Startup repairs on 2026-10-05

The boot journal showed cpupower-gui failing under Python 3.14 because its
`config` parser used a positional `store_true` action. The CLI is patched to
set `apply=True` on the subcommand instead. `--help` and the boot service now
exit successfully.

System changes applied and verified on this host:

- `/usr/bin/cpupower-gui`: replace the invalid argument declaration with
  `config_sub.set_defaults(func=set_config, apply=True)`.
- `/etc/modules-load.d/droidcam.conf`: load the installed `v4l2loopback` module
  instead of the missing `v4l2loopback-dc`. DroidCam supports both.
- `/etc/systemd/system/cpupower-gui.service.d/10-startup-order.conf`: start after
  its helper and before `cpupower.service`.
- `/etc/cpupower_gui.d/99-night-startup.conf`: select `Performance`, preserving
  the governor observed before repair. The old default Balanced would change
  it to powersave; cpupower.service currently has no governor configured.
- Disable autostart for the inactive libvirt pools `windows`,
  `windows_server_2000`, and `WinServer2000`, whose target directories are absent.
  Pool definitions and data are retained.

Original system files are backed up in `/var/lib/boot-repair-20261005/`.
The reviewed repair is reproducible with:

```sh
sudo python3 scripts/maintenance/repair-startup-20261005.py
```

This script is a manual maintenance utility; chezmoi does not automatically
execute it or manage `/usr/bin` and `/etc`. A package upgrade can replace the
patched cpupower-gui CLI. Check upstream compatibility before reapplying it.

To undo the system file changes, restore `cpupower-gui` and `droidcam.conf`
from that backup directory to their original paths, remove the two new drop-in
files listed above, and run `sudo systemctl daemon-reload`. Re-enable pool
autostart only when their storage directories are available.

Desktop changes managed by chezmoi:

- Use Hyprland's `negative:` matcher for the transparent application exclusions;
  RE2 does not support the former negative lookahead.
- Reuse `ii:appearance:settings` for the lazy Settings window's blur rule. Alpha
  thresholds are layer effects and unsupported in a window rule.

Verification: no failed system or user units, successful cpupower-gui service,
Performance governor on all online CPUs, v4l2loopback loaded with a virtual video
device, and no Hyprland configuration errors after reload. A subsequent reboot
has not been tested.
