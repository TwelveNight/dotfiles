#!/usr/bin/env python3
"""Restore personal login routing after niri/Hyprland package upgrades."""
import os
from pathlib import Path
import tempfile


COMMANDS = {
    'niri.desktop': '/home/night/.local/bin/desktop-profile run inir',
    'hyprland.desktop': '/home/night/.local/bin/desktop-profile run hyprland-ii',
    'hyprland-uwsm.desktop': '/home/night/.local/bin/desktop-profile run hyprland-ii -- /usr/bin/uwsm start -e -D Hyprland /usr/bin/start-hyprland',
}


def refresh(directory):
    for name, command in COMMANDS.items():
        path = directory / name
        if path.is_symlink():
            raise ValueError(f'Refusing redirected session file: {path}')
        if not path.is_file():
            continue
        original = path.read_text()
        if sum(line.startswith('Exec=') for line in original.splitlines()) != 1:
            raise ValueError(f'Unexpected session entry layout: {name}')
        updated = ''.join('Exec=' + command + '\n' if line.startswith('Exec=') else line for line in original.splitlines(keepends=True))
        if updated == original:
            continue
        fd, filename = tempfile.mkstemp(prefix='.desktop-profile-', dir=directory)
        temporary = Path(filename)
        try:
            with os.fdopen(fd, 'w') as stream:
                stream.write(updated)
                stream.flush()
                os.fsync(stream.fileno())
            temporary.chmod(0o644)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main():
    if os.geteuid() != 0:
        raise SystemExit('Session refresh requires root')
    refresh(Path('/usr/share/wayland-sessions'))


if __name__ == '__main__':
    main()
