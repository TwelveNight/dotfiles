#!/usr/bin/env python3
"""Read-only source checks; --restore additionally verifies a temporary home.

Requires Python 3.11+, chezmoi, bash, zsh, fish, luac and git.
No application configuration, plugin installer, or desktop session is executed.
"""
import argparse
import ast
from collections import Counter
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib
import warnings as python_warnings

REPO = Path(__file__).resolve().parents[1]
SECRET = re.compile(r"AIza[\w-]{30,}|\b(?:gh[pousr]_[A-Za-z0-9]{20,}|sk-(?:proj-)?[\w-]{24,})|-----BEGIN (?:OPENSSH |RSA |EC )?PRIVATE KEY-----")


def jsonc(text):
    """Remove JSONC comments/trailing commas, respecting strings and escapes."""
    tokens = re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/|[^"/]+|/', re.M)
    chunks = []
    cursor = 0
    for match in tokens.finditer(text):
        if match.start() != cursor:
            raise json.JSONDecodeError('Unterminated JSON string', text, cursor)
        cursor = match.end()
        value = match.group()
        if value.startswith(('//', '/*')):
            chunks.append(' ' + '\n' * value.count('\n'))
        else:
            chunks.append(value)
    if cursor != len(text):
        raise json.JSONDecodeError('Unterminated JSON string', text, cursor)
    cleaned = ''.join(chunks)
    # Protect strings while removing commas followed by a closing bracket.
    cleaned = re.sub(r'"(?:\\.|[^"\\])*"|,(\s*[}\]])',
                     lambda m: m.group(1) if m.group(1) else m.group(), cleaned)
    return json.loads(cleaned)


def confined(root, name):
    relative = Path(name)
    if relative.is_absolute() or '..' in relative.parts or not relative.parts:
        raise ValueError('unsafe target path: ' + name)
    candidate = root / relative
    if not candidate.resolve().is_relative_to(root.resolve()):
        raise ValueError('target escapes temporary home: ' + name)
    return candidate


def run(command, **kwargs):
    return subprocess.run(command, capture_output=True, timeout=60, **kwargs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--restore', action='store_true', help='apply twice in a disposable home; never apply to the real home')
    args = parser.parse_args()
    errors, warnings, counts = [], [], Counter()
    with tempfile.TemporaryDirectory(prefix='chezmoi-check-') as temporary:
        control = Path(temporary)
        home = control / 'home'
        home.mkdir(mode=0o700)
        config_dir = control / 'control'
        config_dir.mkdir(mode=0o700)
        config = config_dir / 'chezmoi.toml'
        config.write_text('[git]\nautoCommit = false\nautoPush = false\n')
        env = os.environ.copy()
        env.update(HOME=str(home), ZDOTDIR=str(home / '.config/zsh'),
                   XDG_CONFIG_HOME=str(home / '.config'), XDG_CACHE_HOME=str(home / '.cache'),
                   XDG_STATE_HOME=str(home / '.local/state'), XDG_DATA_HOME=str(home / '.local/share'))
        # Do not inherit configuration overrides from a caller's shell.
        for key in list(env):
            if key.startswith('CHEZMOI_'):
                env.pop(key)
        base = ['chezmoi', '--source', str(REPO), '--destination', str(home),
                '--config', str(config), '--persistent-state', str(config_dir / 'state.boltdb'),
                '--cache', str(config_dir / 'cache'), '--refresh-externals=never',
                '--exclude=scripts,externals', '--no-tty', '--no-pager']
        result = run(base + ['dump', '--format=json'], env=env)
        if result.returncode:
            print('FAIL: chezmoi could not render the source (diagnostic suppressed to avoid leaking values).')
            return 1
        target = json.loads(result.stdout)
        for name, entry in target.items():
            path = confined(home, name)
            if name.split('/')[0] in {'README.md', 'docs', 'scripts', 'tests', 'AGENTS.md', '.gitignore'}:
                errors.append('repository-only file would be deployed: ' + name)
            if any(p in {'.git', '__pycache__', 'fish_variables', 'cached_layouts'} for p in Path(name).parts):
                errors.append('runtime or VCS state would be deployed: ' + name)
            if entry['type'] == 'symlink':
                link = entry.get('linkname', entry.get('target', ''))
                if not link or Path(link).is_absolute() or not (path.parent / link).resolve().is_relative_to(home):
                    errors.append('unconfined or unknown symlink: ' + name)
            if entry['type'] != 'file':
                continue
            counts['files'] += 1
            contents = entry.get('contents', '')
            if 'contentsBase64' in entry:
                continue
            if SECRET.search(contents):
                errors.append('credential signature in ' + name)
            # Matugen inputs are templates, not finished JSON/Lua/config files.
            if name.startswith('.config/matugen/templates/'):
                counts['matugen templates'] += 1
                continue
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(contents)
            cmd = None
            if name.endswith('.zsh') or Path(name).name in {'.zshenv', '.zshrc'}:
                cmd = ['zsh', '-f', '-n', str(path)]
            elif name.endswith('.fish'):
                cmd = ['fish', '--no-config', '-n', str(path)]
            elif name.endswith('.lua'):
                cmd = ['luac', '-p', str(path)]
            elif contents.startswith(('#!/bin/bash', '#!/usr/bin/env bash', '#! /usr/bin/env bash')):
                cmd = ['bash', '-n', str(path)]
            elif contents.startswith(('#!/bin/sh', '#!/usr/bin/env sh')):
                cmd = ['sh', '-n', str(path)]
            try:
                if name.endswith(('.json', '.jsonc')):
                    jsonc(contents)
                    counts['JSON/JSONC'] += 1
                elif name.endswith('.toml'):
                    tomllib.loads(contents)
                    counts['TOML'] += 1
                elif name.endswith('.py'):
                    with python_warnings.catch_warnings(record=True) as notices:
                        python_warnings.simplefilter('always', SyntaxWarning)
                        ast.parse(contents, filename=name)
                    for notice in notices:
                        warnings.append(name + ':' + str(notice.lineno) + ': Python syntax deprecation')
                    counts['Python'] += 1
            except (ValueError, SyntaxError) as error:
                errors.append(name + ': ' + type(error).__name__ + ' (values suppressed)')
            if cmd:
                if not shutil.which(cmd[0]):
                    errors.append('required validator missing: ' + cmd[0])
                else:
                    checked = run(cmd, env=env)
                    counts[cmd[0]] += 1
                    if checked.returncode:
                        # Only show the location, not diagnostics that may quote private text.
                        errors.append(cmd[0] + ' syntax: ' + name)

        def content(name):
            return target.get(name, {}).get('contents', '')

        required = ['.zshenv', '.config/zsh/.zshenv', '.config/zsh/.zshrc',
                    '.config/zsh/utils/exports.zsh', '.config/zsh/utils/aliases.zsh',
                    '.config/zsh/utils/function.zsh', '.config/zsh/utils/bindkey.zsh',
                    '.config/zsh/plugins/fzf/fzf.plugin.zsh', '.config/starship.toml',
                    '.config/tmux/tmux.reset.conf', '.config/tmux/bin/tmux-template']
        for name in required:
            if name not in target:
                errors.append('required reference missing: ' + name)
        try:
            packages = tomllib.loads(content('.config/yazi/package.toml'))
            declared = {p['use'].split(':')[-1].split('/')[-1] for p in packages.get('plugin', {}).get('deps', [])}
            keymap = tomllib.loads(content('.config/yazi/keymap.toml'))
            if 'manager' in keymap:
                errors.append('obsolete Yazi [manager] table remains')
            plugins = set(re.findall(r'require\(["\']([^"\']+)', content('.config/yazi/init.lua')))
            seen = set()
            for binding in keymap.get('mgr', {}).get('prepend_keymap', []):
                keys = binding['on']
                keys = tuple(keys) if isinstance(keys, list) else (keys,)
                if keys in seen:
                    errors.append('duplicate Yazi mgr shortcut: ' + str(keys))
                seen.add(keys)
                commands = binding['run'] if isinstance(binding['run'], list) else [binding['run']]
                plugins.update(c.split()[1] for c in commands if c.startswith('plugin '))
            for plugin in plugins - declared - {'session', 'fzf', 'zoxide'}:
                if not any('.config/yazi/plugins/' + plugin + '.yazi/' + entry in target for entry in ['main.lua', 'init.lua']):
                    errors.append('Yazi plugin missing from manifest/source: ' + plugin)
            counts['Yazi dependencies'] = len(plugins)
            for name in target:
                if name.startswith('.config/hypr/') and name.endswith('.lua'):
                    for module in re.findall(r'require\(["\']([^"\']+)', content(name)):
                        stem = '.config/hypr/' + module.replace('.', '/')
                        if module.startswith(('hyprland.', 'custom.')) and stem + '.lua' not in target and stem + '/init.lua' not in target:
                            errors.append('Hyprland module missing: ' + module)
            matugen = tomllib.loads(content('.config/matugen/config.toml'))
            for template in matugen.get('templates', {}).values():
                name = template['input_path'].removeprefix('~/')
                if name not in target:
                    errors.append('Matugen input missing: ' + name)
        except (ValueError, KeyError) as error:
            errors.append('dependency manifest invalid: ' + type(error).__name__)

        gitconfig = home / '.config/git/config'
        if gitconfig.exists() and run(['git', 'config', '--file', str(gitconfig), '--list'], env=env).returncode:
            errors.append('Git config cannot be parsed')
        if errors:
            for error in sorted(set(errors)):
                print('FAIL:', error)
            print('Checked:', dict(counts))
            return 1

        if args.restore:
            # Discard parser scratch files so the first apply starts from an empty home.
            shutil.rmtree(home)
            home.mkdir(mode=0o700)
            for attempt in range(2):
                applied = run(base + ['apply'], env=env)
                if applied.returncode:
                    print('FAIL: isolated apply', attempt + 1, '(diagnostic suppressed)')
                    return 1
                verified = run(base + ['verify'], env=env)
                if verified.returncode:
                    print('FAIL: restored contents, permissions, or links differ from source')
                    return 1
                status = run(base + ['status'], env=env)
                if status.returncode or status.stdout.strip():
                    print('FAIL: isolated restore is not idempotent')
                    return 1
                if attempt == 0:
                    # A generated theme must survive subsequent dotfile restores.
                    for name, marker in {
                        '.config/hypr/hyprland/colors.lua': '-- generated theme preservation check\n',
                        '.config/hypr/hyprland/shellOverrides/main.lua': '-- shell override preservation check\n',
                        '.config/hypr/hyprlock/colors.conf': '# generated theme preservation check\n',
                        '.config/ghostty/themes/material': '# generated theme preservation check\n',
                    }.items():
                        (home / name).write_text(marker)
                else:
                    for name in ['.config/hypr/hyprland/colors.lua', '.config/hypr/hyprland/shellOverrides/main.lua',
                                 '.config/hypr/hyprlock/colors.conf', '.config/ghostty/themes/material']:
                        if 'preservation check' not in (home / name).read_text():
                            print('FAIL: generated file overwritten:', name)
                            return 1
            for path in home.rglob('*'):
                if not path.resolve().is_relative_to(home):
                    print('FAIL: restored link escapes temporary home')
                    return 1
            print('PASS: two isolated restores; contents, modes, links and idempotence verified.')
        print('PASS:', dict(counts))
        for warning in warnings:
            print('WARN:', warning)
        print('INFO: desktop rendering, input methods, interactive shortcuts and online plugin installation require manual verification.')
        # Filenames only; do not emit configuration contents or secret-bearing diffs.
        drift = run(['chezmoi', '--source', str(REPO), '--config', str(config),
                     '--persistent-state', str(config_dir / 'live-read-state.boltdb'),
                     '--cache', str(config_dir / 'live-cache'), '--refresh-externals=never',
                     '--exclude=scripts,externals', 'status'])
        if drift.returncode:
            print('WARN: live drift could not be read.')
        else:
            lines = drift.stdout.decode().splitlines()
            print('INFO: live home has', len(lines), 'pending entries; no files were applied there.')
            for line in lines:
                print(' ', line)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
