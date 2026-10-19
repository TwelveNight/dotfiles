#!/usr/bin/env python3
"""Move the three installed configurations into desktop-profiles, with rollback."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

from desktop_profiles import Profiles


def normalize(text):
    text = text.replace('.config/nyxuri-desktop/', '.config/')
    text = text.replace('".config/nyxuri-desktop"', '".config"')
    text = text.replace('"$HOME/.config/nyxuri-desktop"', '"$HOME/.config"')
    text = text.replace('"/home/night/.config/nyxuri-desktop"', '"/home/night/.config"')
    text = text.replace('/nyxuri-desktop/\' + app', '/\' + app')
    text = text.replace('/ "nyxuri-desktop" / "noctalia" / "tools"', '/ "noctalia" / "tools"')
    text = text.replace('"nyxuri-desktop", "noctalia",', '"noctalia",')
    text = text.replace('}/nyxuri-desktop/', '}/')
    text = text.replace('}/nyxuri-desktop"', '}"')
    return text


def source_plan(home):
    config = home / '.config'
    root = config / 'desktop-profiles'
    return [(config / 'hypr', root / 'hyprland-ii/hypr'),
            (config / 'niri', root / 'inir/niri'),
            (config / 'nyxuri-desktop', root / 'nyxuri')]


def validate(home):
    config = home / '.config'
    for source, target in source_plan(home):
        if source.is_symlink() or not source.is_dir():
            raise ValueError(f'Expected original installed directory: {source}')
        if target.exists() or target.is_symlink():
            raise ValueError(f'Profile destination already exists: {target}')
    for app in ('noctalia',):
        path = config / app
        if path.exists() or path.is_symlink():
            raise ValueError(f'Unexpected existing standard configuration: {path}')
    # Relocate the live Hyprland directory without editing its contents. The
    # Niri layouts cannot be rewritten while either Niri session is running.
    for directory in Path('/proc').iterdir():
        if not directory.name.isdigit():
            continue
        try:
            if directory.stat().st_uid == os.getuid() and (directory / 'comm').read_text().strip() == 'niri':
                raise ValueError('Log out of Niri before migrating its configuration')
        except OSError:
            continue


def rollback(home, backup):
    journal = json.loads((backup / 'journal.json').read_text())
    for filename, entry in journal['files'].items():
        path = Path(filename)
        if entry['exists']:
            path.parent.mkdir(parents=True, exist_ok=True)
            saved = backup / entry['backup']
            if path.is_symlink():
                path.unlink()
            if saved.is_symlink():
                path.unlink(missing_ok=True)
                path.symlink_to(os.readlink(saved))
            else:
                shutil.copy2(saved, path)
        else:
            path.unlink(missing_ok=True)
    for filename in journal['created_links']:
        path = Path(filename)
        if path.is_symlink():
            path.unlink()
    for source, target in reversed(source_plan(home)):
        if target.exists() and not source.exists():
            target.rename(source)
    # Restore Nyxuri's pre-migration path contents; keep the profile copy for review.
    original = home / '.config/nyxuri-desktop'
    if original.is_dir():
        original.rename(backup / 'nyxuri-after-migration')
        shutil.copytree(backup / 'nyxuri-original', original, symlinks=True)
    legacy_kitty = backup / 'legacy-kitty-nyxuri'
    if legacy_kitty.exists():
        legacy_kitty.rename(home / '.config/kitty-nyxuri')
    for filename in journal.get('new_files', []):
        Path(filename).unlink(missing_ok=True)


def apply(home, package):
    validate(home)
    config = home / '.config'
    root = config / 'desktop-profiles'
    backup = home / '.local/state/desktop-profiles' / ('migration-' + time.strftime('%Y%m%d-%H%M%S'))
    backup.mkdir(parents=True, mode=0o700)
    shutil.copytree(config / 'nyxuri-desktop', backup / 'nyxuri-original', symlinks=True)
    journal = {'files': {}, 'created_links': [], 'new_files': []}

    def persist():
        (backup / 'journal.json').write_text(json.dumps(journal, indent=2))

    def save(path):
        key = str(path)
        if key in journal['files']:
            return
        present = path.exists() or path.is_symlink()
        entry = {'exists': present}
        if present:
            relative = 'files/' + str(path.relative_to(home))
            dest = backup / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            if path.is_symlink():
                dest.symlink_to(os.readlink(path))
            else:
                shutil.copy2(path, dest)
            entry['backup'] = relative
        journal['files'][key] = entry
        persist()

    def write(path, content, mode=None):
        save(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.is_symlink():
            path.unlink()
        path.write_text(content)
        if mode is not None:
            path.chmod(mode)

    persist()
    try:
        old_kitty = config / 'kitty-nyxuri'
        if old_kitty.exists() or old_kitty.is_symlink():
            old_kitty.rename(backup / 'legacy-kitty-nyxuri')
        for source, target in source_plan(home):
            target.parent.mkdir(parents=True, exist_ok=True)
            source.rename(target)
        nyxuri = root / 'nyxuri'
        for path in nyxuri.rglob('*'):
            if path.is_symlink():
                target = path.readlink()
                original_root = config / 'nyxuri-desktop'
                if target.is_absolute() and target.is_relative_to(original_root):
                    replacement = nyxuri / target.relative_to(original_root)
                    path.unlink()
                    path.symlink_to(os.path.relpath(replacement, path.parent))
                continue
            if not path.is_file() or path.suffix not in ('.py', '.sh', '.toml', '.kdl', '.lua', '.conf', '.md', '.desktop'):
                continue
            try:
                text = path.read_text()
            except UnicodeDecodeError:
                continue
            changed = normalize(text)
            if changed != text:
                path.write_text(changed)
        registry = (package / 'profiles.json').read_text()
        write(root / 'profiles.json', registry, 0o600)
        for app, owner in [('hypr', 'hyprland-ii'), ('niri', 'inir'), ('noctalia', 'nyxuri'), ('kitty-nyxuri', 'nyxuri')]:
            link = config / app
            journal['created_links'].append(str(link))
            persist()
            link.symlink_to(Path('desktop-profiles') / owner / app)
        for name in ('nyxuri-niri.service', 'nyxuri-shell.service', 'nyxuri-clipboard.service'):
            path = config / 'systemd/user' / name
            write(path, normalize(path.read_text()))
        # GUI overrides can retain local plugin sources and take precedence over
        # the migrated configuration. Preserve all preferences and journal this
        # path-only update alongside the other reversible user-file changes.
        settings = home / '.local/state/nyxuri-desktop/noctalia/noctalia/settings.toml'
        if settings.is_file():
            text = settings.read_text()
            updated = normalize(text)
            if updated != text:
                write(settings, updated)
        installer = home / '.local/bin/nyxuri'
        save(installer)
        installer.unlink()
        installer.symlink_to(home / 'Template/github/niri-dots/Nyxuri-personal/install.sh')
        # Every user file changed by the migration can be restored from this journal.
        write(backup / 'README.txt', 'Restore from a TTY with:\npython3 ~/.local/lib/desktop-profiles/migrate.py --rollback ' + str(backup) + '\n')
        Profiles(home).guard('inir')
        print(f'Configuration migration complete. Backup: {backup}')
        return backup
    except BaseException:
        rollback(home, backup)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--rollback', type=Path)
    args = parser.parse_args()
    home = Path.home()
    if args.rollback:
        rollback(home, args.rollback)
    elif args.apply:
        apply(home, Path(__file__).resolve().parent)
    else:
        validate(home)
        for source, target in source_plan(home):
            print(f'{source} -> {target}')
        print('Create standard configuration links; normalize Nyxuri paths; preserve GUI state and compositor files.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print(f'Migration stopped: {error}', file=sys.stderr)
        raise SystemExit(1)
