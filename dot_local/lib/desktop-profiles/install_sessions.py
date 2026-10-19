#!/usr/bin/env python3
"""Install only the four reviewed GDM session launchers (requires root)."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


def main():
    if os.geteuid() != 0:
        raise SystemExit('Run with pkexec or sudo to register the four GDM login entries.')
    package = Path(__file__).resolve().parent
    destination = Path('/usr/share/wayland-sessions')
    expected = json.loads((package / 'sessions-before-sha256.json').read_text())
    allowed = {'niri.desktop', 'nyxuri.desktop', 'hyprland.desktop', 'hyprland-uwsm.desktop'}
    if set(expected) != allowed:
        raise ValueError('Unexpected session installation scope')
    for name, digest in expected.items():
        target = destination / name
        proposed = package / 'sessions' / name
        if target.is_symlink() or not proposed.is_file():
            raise ValueError(f'Unexpected session path: {name}')
        if hashlib.sha256(target.read_bytes()).hexdigest() != digest and target.read_bytes() != proposed.read_bytes():
            raise ValueError(f'{name} changed since review; no session entries installed')
    backup = Path('/var/lib/desktop-profiles') / time.strftime('sessions-%Y%m%d-%H%M%S')
    backup.mkdir(parents=True, mode=0o700)
    changed = []
    system_files = {
        Path('/usr/local/lib/desktop-profiles/refresh_sessions.py'): package / 'refresh_sessions.py',
        Path('/etc/pacman.d/hooks/95-desktop-profiles.hook'): package / '95-desktop-profiles.hook',
    }
    new_system = []
    migration_backup = None
    try:
        home = Path('/home/night')
        profiles = home / '.config/desktop-profiles'
        if not (profiles / 'inir/niri/config.kdl').is_file():
            state = home / '.local/state/desktop-profiles'
            before = set(state.glob('migration-*')) if state.exists() else set()
            subprocess.run(['/usr/bin/runuser', '-u', 'night', '--', '/usr/bin/python3', str(package / 'migrate.py'), '--apply'], check=True)
            added = set(state.glob('migration-*')) - before
            if len(added) != 1:
                raise ValueError('Could not identify configuration migration backup')
            migration_backup = added.pop()
        for target, source in system_files.items():
            if target.exists() or target.is_symlink():
                raise ValueError(f'System integration already exists; review before replacing: {target}')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            target.chmod(0o644)
            new_system.append(target)
        for name in sorted(allowed):
            target = destination / name
            shutil.copy2(target, backup / name)
            handle, temporary_name = tempfile.mkstemp(prefix='.desktop-profile-', dir=destination)
            temporary = Path(temporary_name)
            try:
                with os.fdopen(handle, 'wb') as stream:
                    stream.write((package / 'sessions' / name).read_bytes())
                    stream.flush()
                    os.fsync(stream.fileno())
                temporary.chmod(0o644)
                os.replace(temporary, target)
                changed.append(name)
            finally:
                temporary.unlink(missing_ok=True)
    except BaseException:
        for name in changed:
            shutil.copy2(backup / name, destination / name)
        for target in new_system:
            target.unlink(missing_ok=True)
        if migration_backup:
            subprocess.run(['/usr/bin/runuser', '-u', 'night', '--', '/usr/bin/python3', str(package / 'migrate.py'), '--rollback', str(migration_backup)], check=False)
        raise
    print(f'Installed four GDM session launchers. Original files: {backup}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print(f'Session registration stopped: {error}', file=sys.stderr)
        raise SystemExit(1)
