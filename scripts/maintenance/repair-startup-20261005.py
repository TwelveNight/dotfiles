#!/usr/bin/python3
"""Repair the two identified startup compatibility errors; back up before writing."""
from pathlib import Path
import os, shutil, subprocess

if os.geteuid() != 0:
    raise SystemExit('Run with sudo python3 ' + str(Path(__file__).resolve()))
cpupower = Path('/usr/bin/cpupower-gui')
modules = Path('/etc/modules-load.d/droidcam.conf')
old = 'config_sub.add_argument(\n    "apply", action="store_true", help="apply cpupower configuration",\n)\nconfig_sub.set_defaults(func=set_config)'
new = 'config_sub.set_defaults(func=set_config, apply=True)'
content = cpupower.read_text()
module_content = modules.read_text()
if old not in content and new not in content:
    raise SystemExit('cpupower-gui changed unexpectedly; no files modified')
if 'v4l2loopback-dc' not in module_content.splitlines() and 'v4l2loopback' not in module_content.splitlines():
    raise SystemExit('droidcam.conf changed unexpectedly; no files modified')
subprocess.run(['modinfo', 'v4l2loopback'], check=True, stdout=subprocess.DEVNULL)
backup = Path('/var/lib/boot-repair-20261005')
backup.mkdir(mode=0o700, exist_ok=True)
for path, name in [(cpupower, 'cpupower-gui'), (modules, 'droidcam.conf')]:
    target = backup / name
    if not target.exists():
        shutil.copy2(path, target)
if old in content:
    patched = content.replace(old, new)
    compile(patched, str(cpupower), 'exec')
    cpupower.write_text(patched)
if 'v4l2loopback-dc' in module_content.splitlines():
    modules.write_text('\n'.join('v4l2loopback' if line == 'v4l2loopback-dc' else line for line in module_content.splitlines()) + '\n')
subprocess.run([str(cpupower), '--help'], check=True, stdout=subprocess.DEVNULL)
subprocess.run(['modprobe', 'v4l2loopback'], check=True)
ordering = Path('/etc/systemd/system/cpupower-gui.service.d/10-startup-order.conf')
ordering_text = '[Unit]\nAfter=cpupower-gui-helper.service\nBefore=cpupower.service\n'
if ordering.exists() and ordering.read_text() != ordering_text:
    raise SystemExit('Existing startup ordering override differs; inspect manually')
ordering.parent.mkdir(parents=True, exist_ok=True)
ordering.write_text(ordering_text)
subprocess.run(['systemctl', 'daemon-reload'], check=True)
profile = Path('/etc/cpupower_gui.d/99-night-startup.conf')
profile_text = '[Profile]\nprofile = Performance\n'
if profile.exists() and profile.read_text() != profile_text:
    raise SystemExit('Existing startup profile differs; inspect manually')
profile.write_text(profile_text)
subprocess.run(['systemctl', 'restart', 'cpupower-gui.service'], check=True)
subprocess.run(['systemctl', 'restart', 'cpupower.service'], check=True)
subprocess.run(['systemctl', '--failed', '--no-pager'], check=True)
subprocess.run(['systemctl', 'show', 'cpupower-gui.service', '-p', 'Result', '-p', 'ExecMainStatus'], check=True)
print('System repairs verified. Backups:', backup)
