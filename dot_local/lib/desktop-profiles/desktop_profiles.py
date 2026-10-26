#!/usr/bin/env python3
"""Select installed desktop configurations before starting a login session."""
import argparse
from contextlib import contextmanager, ExitStack
import fcntl
import json
import os
from pathlib import Path
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
from session_runtime import prepare_session
from fcitx_theme import DEFAULT as FCITX_DEFAULT, render as render_fcitx, select_theme, reload_classicui, verify_contract


SKWD_PROFILES = {"inir", "nyxuri", "hyprland-ii"}
WALLPAPER_UNITS = ("ii-skwd-wall-theme.service", "skwd-walld.service")
THEME_PROFILES = {"inir", "nyxuri", "hyprland-ii", "sekaipop", "vitreus", "vitreus-wm", "dms-niri", "vitreus-niri"}
EDITOR_KEYS = ("workbench.colorTheme", "workbench.preferredDarkColorTheme",
               "workbench.preferredLightColorTheme", "window.autoDetectColorScheme",
               "workbench.colorCustomizations", "editor.tokenColorCustomizations",
               "editor.semanticTokenColorCustomizations", "inir.previousColorTheme")
EDITOR_FORKS = ("Code", "VSCodium", "Code - OSS", "Code - Insiders", "Cursor",
                "Windsurf", "Windsurf - Next", "Qoder", "Antigravity", "Positron",
                "Void", "Melty", "PearAI", "Aide")
EXTENSION_BASES = (".vscode", ".vscode-oss", ".vscode-insiders", ".cursor", ".windsurf",
                   ".windsurf-next", ".qoder", ".antigravity", ".positron", ".void",
                   ".melty", ".pearai", ".aide")


def jsonc_fields(text):
    """Parse JSONC objects, retaining source offsets for lossless key edits."""
    pattern = re.compile(r'\s+|//[^\r\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'
                         r'-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null|[{}\[\]:,]')
    tokens, offset = [], 0
    for match in pattern.finditer(text):
        if match.start() != offset:
            raise ValueError("Invalid JSONC settings; original left unchanged")
        offset = match.end()
        value = match[0]
        if not (value.isspace() or value.startswith(("//", "/*"))):
            tokens.append((value, match.start(), match.end()))
    if offset != len(text) or not tokens or tokens[0][0] != "{":
        raise ValueError("Expected a JSONC settings object")
    # Validate full syntax first, including nested values and trailing commas.
    plain = ' '.join(t[0] for i, t in enumerate(tokens)
                    if not (t[0] == ',' and i + 1 < len(tokens) and tokens[i + 1][0] in (']', '}')))
    parsed = json.loads(plain)
    if not isinstance(parsed, dict):
        raise ValueError("Expected a JSONC settings object")
    fields, i, previous_comma = {}, 1, None
    while tokens[i][0] != "}":
        key_token = tokens[i]
        key = json.loads(key_token[0])
        if key in fields:
            raise ValueError("Duplicate JSONC setting; original left unchanged")
        value_start = i + 2
        end = value_start
        if tokens[end][0] in ("{", "["):
            depth = 1
            while depth:
                end += 1
                if tokens[end][0] in ("{", "["):
                    depth += 1
                elif tokens[end][0] in ("}", "]"):
                    depth -= 1
        comma = end + 1 if tokens[end + 1][0] == "," else None
        fields[key] = dict(start=key_token[1], value_start=tokens[value_start][1],
                           end=tokens[end][2], comma=tokens[comma][1] if comma else None,
                           comma_end=tokens[comma][2] if comma else None, previous_comma=previous_comma)
        previous_comma = tokens[comma][1] if comma else None
        i = comma + 1 if comma else end + 1
    return fields, tokens[i][1]


def color_settings(text, keys):
    fields, _ = jsonc_fields(text)
    return {key: text[fields[key]["value_start"]:fields[key]["end"]]
            for key in keys if key in fields}


def merge_color_settings(text, keys, values):
    fields, _ = jsonc_fields(text)
    edits, removals = [], []
    for key in keys:
        if key not in fields:
            continue
        f = fields[key]
        if key in values:
            edits.append((f["value_start"], f["end"], values[key]))
        elif f["comma"] is not None:
            removals.append((f["start"], f["comma_end"]))
        else:
            removals.append((f["previous_comma"] if f["previous_comma"] is not None else f["start"], f["end"]))
    merged = []
    for start, end in sorted(removals):
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(end, merged[-1][1]))
        else:
            merged.append((start, end))
    edits += [(start, end, "") for start, end in merged]
    for start, end, replacement in sorted(edits, reverse=True):
        text = text[:start] + replacement + text[end:]
    missing = {key: value for key, value in values.items() if key in keys and key not in fields}
    if missing:
        remaining, close = jsonc_fields(text)
        if remaining:
            last = list(remaining.values())[-1]
            if last["comma"] is None:
                text = text[:last["end"]] + ',' + text[last["end"]:]
                close += 1
        additions = ''.join(f'\n    {json.dumps(key)}: {value},' for key, value in missing.items()) + '\n'
        text = text[:close] + additions + text[close:]
    jsonc_fields(text)
    return text


def write_text(path, text):
    """Retain managed symlinks and file permissions on an atomic update."""
    target = path.resolve() if path.is_symlink() else path
    if target.exists() and target.read_text() == text:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".desktop-colors-", dir=target.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.chmod(temporary, target.stat().st_mode & 0o777 if target.exists() else 0o600)
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)


def theme_writer_pids(proc, profile):
    """Find only this login's palette workers and their children, never apps by name."""
    processes, roots = {}, set()
    for directory in proc.iterdir():
        if not directory.name.isdigit():
            continue
        try:
            if directory.stat().st_uid != os.getuid():
                continue
            pid = int(directory.name)
            comm = (directory / "comm").read_text().strip()
            if comm in ("niri", "Hyprland", "pleamar-wm"):
                raise ValueError("A compositor is still running; defer theme recovery until logout")
            status = (directory / "status").read_text()
            parent = int(re.search(r"^PPid:\s+(\d+)", status, re.M)[1])
            processes[pid] = parent
            marker = f"DESKTOP_PROFILE={profile}".encode()
            if marker not in (directory / "environ").read_bytes().split(b"\0"):
                continue
            args = (directory / "cmdline").read_bytes().decode(errors="replace").split("\0")
            if (any(arg.startswith("/") and ("/scripts/colors/" in arg or arg.endswith("/quickshell-guard/qs-guard.sh")) for arg in args)
                    or comm == "matugen" or any("kde-material-you-colors" in arg for arg in args)
                    or (profile in ("vitreus", "vitreus-wm", "vitreus-niri") and (comm in ("pleamar", "awww-daemon", "hypridle", "mpvpaper")
                        or any("/vitreus/bin/vitreus-keep" in arg for arg in args)))
                    or (comm in ("qs", "quickshell") and any(arg in ("ii", "inir", "sekaipop") for arg in args))):
                roots.add(pid)
        except (OSError, TypeError, IndexError):
            continue
    selected = set(roots)
    while True:
        children = {pid for pid, parent in processes.items() if parent in selected}
        if children <= selected:
            return selected
        selected.update(children)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(temporary, path)


class ThemeSession:
    """Temporarily route theme files into the selected desktop's profile.

    Keep the original entries themselves (including symlinks), not copies of
    their contents. A journal lets the next login recover after a killed login
    launcher. Only call while the session/transition locks exclude a compositor.
    """
    KEYS = ("color-scheme", "gtk-theme", "icon-theme", "cursor-theme", "cursor-size",
            "font-name", "monospace-font-name")
    CORE = ("gtk-3.0", "gtk-4.0", "qt5ct", "qt6ct", "kdeglobals", "kcminputrc")
    APPS = ("kitty", "foot", "alacritty", "wezterm", "ghostty", "btop", "lazygit",
            "yazi", "fuzzel", "rofi", "Kvantum", "matugen", "starship", "starship.toml",
            "oh-my-posh", "opencode/themes", "zed/themes", "vesktop/themes")

    def __init__(self, home, profile="sekaipop"):
        self.home = Path(home)
        self.requested_profile = profile
        self.transaction = self.home / ".local/state/desktop-profiles/theme-session"
        self.journal = self.transaction / "journal.json"
        self.configure(profile)

    def configure(self, profile, paths=None):
        if profile not in THEME_PROFILES:
            raise ValueError(f"Unsupported theme profile: {profile}")
        self.profile = profile
        self.root = self.home / ".config/desktop-profiles" / profile / "theme"
        known = {f".config/{name}": self.root / name for name in self.CORE + self.APPS}
        known.update({".local/share/icons/default": self.root / "icons/default",
                      ".icons/default": self.root / "legacy-icons/default",
                      ".local/state/quickshell/user/generated": self.root / "generated",
                      ".local/share/color-schemes": self.root / "data/color-schemes",
                      ".local/share/konsole": self.root / "data/konsole",
                      ".local/share/fcitx5/themes/nyxmellow": self.root / "data/fcitx5/nyxmellow",
                      ".config/fcitx5/conf/classicui.conf": self.root / "fcitx5/classicui.conf"})
        if profile in ("vitreus", "vitreus-wm", "vitreus-niri"):
            # Preserve the pre-existing Marea/pleamar setup and idle policy.
            known.update({".config/pleamar": self.root / "pleamar",
                          ".config/hypridle": self.root / "hypridle",
                          ".cache/awww": self.root / "cache/awww"})
            for scene in ("vitreus", "lockscreen", "wptrans", "desktopclock", "desktopsysmon",
                          "desktopnotes", "desktopmenu", "desktopedit", "desktopcards", "snap", "files", "webcam", "session"):
                known[f".local/share/pleamar/{scene}"] = self.root / "data/pleamar" / scene
            known[".local/state/pleamar-wm"] = self.root / "state/pleamar-wm"
            known[".cache/pleamar-wm"] = self.root / "cache/pleamar-wm"
        for base in EXTENSION_BASES:
            extensions = self.home / base / "extensions"
            names = {"inir-material-theme"} if extensions.is_dir() else set()
            names.update(p.name for p in extensions.glob("illogical-impulse.ii-material-you-*") if p.is_dir())
            # Recovery must also recognize an extension removed by its writer.
            if paths:
                names.update(Path(p).name for p in paths if p.startswith(base + "/extensions/")
                             and re.fullmatch(r"illogical-impulse\.ii-material-you-[\w.+-]+", Path(p).name))
            for name in names:
                known[f"{base}/extensions/{name}"] = self.root / "editor-extensions" / base / name
            known[f"{base}/extensions/inir-material-theme"] = self.root / "editor-extensions" / base / "inir-material-theme"
        if paths is None:
            paths = [f".config/{name}" for name in self.CORE + self.APPS]
            if profile in ("vitreus", "vitreus-wm", "vitreus-niri"):
                paths += [".config/pleamar", ".config/hypridle", ".cache/awww"]
                paths += [key for key in known if key.startswith((".local/share/pleamar/", ".local/state/pleamar-wm", ".cache/pleamar-wm"))]
            paths += [".local/share/icons/default", ".icons/default"]
            paths += [".local/state/quickshell/user/generated", ".local/share/color-schemes",
                      ".local/share/fcitx5/themes/nyxmellow", ".local/share/konsole",
                      ".config/fcitx5/conf/classicui.conf"]
            paths += [key for key in known if key not in paths and (self.home / key).exists()]
            paths += [f"{base}/extensions/inir-material-theme" for base in EXTENSION_BASES
                      if (self.home / base / "extensions").is_dir()
                      and f"{base}/extensions/inir-material-theme" not in paths]
        if any(key not in known for key in paths):
            raise ValueError("Unexpected theme recovery path; journal left unchanged")
        self.bindings = [(self.home / key, known[key]) for key in paths]

    def settings_paths(self):
        result = {}
        for name in EDITOR_FORKS:
            key = f".config/{name}/User/settings.json"
            if (self.home / key).parent.is_dir():
                result[key] = EDITOR_KEYS
        if (self.home / ".config/zed").is_dir():
            result[".config/zed/settings.json"] = ("theme", "experimental.theme_overrides")
        return self.valid_settings_paths(result)

    def valid_settings_paths(self, paths):
        result = dict(paths)
        for key, keys in list(result.items()):
            path = self.home / key
            if path.exists():
                try:
                    color_settings(path.read_text(), keys)
                except (OSError, ValueError):
                    # One broken editor config must not prevent desktop login.
                    # Writers also leave malformed JSONC alone; never repair or
                    # replace unrelated editor settings as part of theming.
                    print(f"desktop-profile: invalid editor settings left unchanged: {path}", file=sys.stderr)
                    del result[key]
        return result

    def snapshot_editors(self, paths):
        return {key: color_settings((self.home / key).read_text() if (self.home / key).exists() else '{}', keys)
                for key, keys in paths.items()}

    def apply_editors(self, paths, values):
        for key, keys in paths.items():
            path = self.home / key
            text = path.read_text() if path.exists() else '{}'
            result = merge_color_settings(text, keys, values[key])
            # Do not create empty settings files for newly installed editors.
            if path.exists() or color_settings(result, keys):
                write_text(path, result)

    def extension_registries(self):
        return [f"{base}/extensions/extensions.json" for base in EXTENSION_BASES
                if (self.home / base / "extensions").is_dir()]

    def registry_entries(self, key):
        path = self.home / key
        entries = json.loads(path.read_text()) if path.exists() else []
        if not isinstance(entries, list) or any(not isinstance(entry, dict) for entry in entries):
            raise ValueError(f"Invalid editor extension registry: {path}")
        return entries

    def snapshot_registries(self, keys):
        return {key: [entry for entry in self.registry_entries(key)
                      if entry.get("identifier", {}).get("id") == "inir.inir-material-theme"] for key in keys}

    def apply_registries(self, keys, saved):
        for key in keys:
            entries = [entry for entry in self.registry_entries(key)
                       if entry.get("identifier", {}).get("id") != "inir.inir-material-theme"]
            entries += saved[key]
            path = self.home / key
            if path.exists() or entries:
                write_text(path, json.dumps(entries, indent=2) + "\n")

    def dconf(self, action, key, value=None):
        command = ["dconf", action, f"/org/gnome/desktop/interface/{key}"]
        if value is not None:
            command.append(value)
        return subprocess.run(command, check=True, text=True, capture_output=True, timeout=15).stdout.strip()

    def interface(self):
        return {key: self.dconf("read", key) for key in self.KEYS}

    def apply_interface(self, values):
        for key in self.KEYS:
            if key not in values:  # Compatible with the original five-key journal.
                continue
            if values[key]:
                self.dconf("write", key, values[key])
            else:
                self.dconf("reset", key)

    def normalize_links(self, target):
        if not target.is_dir():
            return
        for child in target.rglob("*"):
            if not child.is_symlink():
                continue
            raw = Path(os.path.abspath(child.parent / os.readlink(child)))
            for canonical, storage in self.bindings:
                if raw.is_relative_to(canonical):
                    destination = storage / raw.relative_to(canonical)
                    child.unlink()
                    child.symlink_to(os.path.relpath(destination, child.parent))
                    break
            if not child.resolve().is_relative_to(self.root):
                raise ValueError(f"Theme storage contains redirected files: {child}")

    def stop_writers(self):
        # Capture worker descendants before stopping their parent shell. iNiR
        # intentionally uses KillMode=process so app launches survive a shell
        # restart; its detached palette helpers still need draining at logout.
        selected = theme_writer_pids(Path("/proc"), self.profile)
        descriptors = {}
        try:
            for pid in selected:
                try:
                    descriptors[pid] = os.pidfd_open(pid)
                except ProcessLookupError:
                    pass
            confirmed = theme_writer_pids(Path("/proc"), self.profile)
            for pid in list(descriptors):
                if pid not in confirmed:
                    os.close(descriptors.pop(pid))
            units = [*WALLPAPER_UNITS,
                     {"vitreus": "vitreus-shell.service", "vitreus-wm": "vitreus-shell.service", "vitreus-niri": "vitreus-shell.service", "sekaipop": "sekaipop-shell.service", "inir": "inir.service",
                      "nyxuri": "nyxuri-shell.service", "hyprland-ii": "hyprland-session.target",
                      "dms-niri": "dms.service"}[self.profile]]
            result = subprocess.run(["systemctl", "--user", "stop", *units], check=False, timeout=30)
            if result.returncode not in (0, 5):
                raise ValueError("Cannot stop desktop theme writers; theme journal retained")
            for fd in descriptors.values():
                try:
                    signal.pidfd_send_signal(fd, signal.SIGTERM)
                except ProcessLookupError:
                    pass
            pending = list(descriptors.values())
            deadline = time.monotonic() + 5
            while pending and time.monotonic() < deadline:
                ready, _, _ = select.select(pending, [], [], max(0, deadline - time.monotonic()))
                pending = [fd for fd in pending if fd not in ready]
            for fd in pending:
                try:
                    signal.pidfd_send_signal(fd, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            if pending and len(select.select(pending, [], [], 5)[0]) != len(pending):
                raise ValueError("Palette workers did not exit; theme journal retained")
            if theme_writer_pids(Path("/proc"), self.profile):
                # A worker may have spawned during unit shutdown. Never expose
                # the original paths until the remaining producer is drained.
                raise ValueError("Palette workers remain after shutdown; theme journal retained")
        finally:
            for fd in descriptors.values():
                os.close(fd)

    def recover(self, save=False):
        if not self.journal.exists():
            return
        data = json.loads(self.journal.read_text())
        # v1 journals belong to SekaiPop and had exactly its six system paths
        # plus two cursor paths. Keep recovery compatible with the prior release.
        legacy = [f".config/{name}" for name in self.CORE] + [".local/share/icons/default", ".icons/default"]
        self.configure(data.get("profile", "sekaipop"), data.get("paths", legacy))
        self.stop_writers()
        if data["interface_active"]:
            if save:
                write_json(self.root / "interface.json", self.interface())
            self.apply_interface(data["interface"])
            editors = self.valid_settings_paths(data.get("editors", {}))
            # Editor snapshots contain only color-related keys. Non-color
            # preferences changed during the session stay shared.
            if save and editors:
                saved = self.root / "editor-colors.json"
                previous = json.loads(saved.read_text()) if saved.exists() else {}
                write_json(saved, previous | self.snapshot_editors(editors))
            self.apply_editors(editors, data.get("editor_original", {}))
            registries = data.get("registries", [])
            if save and registries:
                write_json(self.root / "editor-registration.json", self.snapshot_registries(registries))
            self.apply_registries(registries, data.get("registry_original", {}))
        for i, (path, target) in enumerate(self.bindings):
            original = self.transaction / str(i)
            selected = path.is_symlink() and path.resolve() == target
            if os.path.lexists(original) or not data["present"][i]:
                if selected:
                    path.unlink()
                elif os.path.lexists(path):
                    # Qt/KConfig can atomically replace the canonical FILE
                    # link. Keep that session's new contents in its profile.
                    if path.is_symlink() or not path.is_file() or target.is_dir():
                        raise ValueError(f"Theme entry changed unexpectedly; original retained at {original}: {path}")
                    os.replace(path, target)
                if os.path.lexists(original):
                    os.replace(original, path)
        shutil.rmtree(self.transaction)
        if ".config/fcitx5/conf/classicui.conf" in data.get("paths", []):
            reload_classicui()

    @contextmanager
    def activate(self):
        self.recover()
        self.configure(self.requested_profile)
        if self.root.absolute() != self.root.resolve():
            raise ValueError(f"Theme storage must not be redirected: {self.root}")
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        # Copy the current preferences once. Dereference source links so theme
        # writes cannot modify a sibling desktop or a chezmoi source file.
        for path, target in self.bindings:
            if path.parent.absolute() != path.parent.resolve():
                raise ValueError(f"Theme parent must not be redirected: {path.parent}")
            if target.is_symlink() or target.absolute() != target.resolve():
                raise ValueError(f"Theme storage must not be redirected: {target}")
            if not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                if path.is_dir():
                    shutil.copytree(path, target)
                elif path.is_file():
                    shutil.copy2(path, target)
                elif path.name in ("kdeglobals", "kcminputrc", "starship.toml", "classicui.conf"):
                    target.touch()
                else:
                    target.mkdir()
            self.normalize_links(target)
        fcitx = self.root / "fcitx5/classicui.conf"
        write_text(fcitx, select_theme(fcitx.read_text()))
        theme = self.root / "data/fcitx5/nyxmellow"
        if not all((theme / name).is_file() for name in ("theme.conf", "panel.svg", "highlight.svg")):
            render_fcitx(theme, FCITX_DEFAULT)
        editors = self.settings_paths()
        registries = self.extension_registries()
        data = {"profile": self.profile, "paths": [str(p.relative_to(self.home)) for p, _ in self.bindings],
                "present": [os.path.lexists(p) for p, _ in self.bindings],
                "interface": self.interface(), "interface_active": False,
                "editors": editors, "editor_original": self.snapshot_editors(editors),
                "registries": registries, "registry_original": self.snapshot_registries(registries)}
        write_json(self.journal, data)
        try:
            for i, (path, target) in enumerate(self.bindings):
                path.parent.mkdir(parents=True, exist_ok=True)
                if data["present"][i]:
                    os.replace(path, self.transaction / str(i))
                Profiles.replace_link(path, target)
            data["interface_active"] = True
            write_json(self.journal, data)
            saved = self.root / "interface.json"
            if saved.exists():
                # New interface keys inherit the current shared preference once.
                values = data["interface"] | json.loads(saved.read_text())
                self.apply_interface(values)
            saved = self.root / "editor-colors.json"
            if saved.exists():
                values = data["editor_original"] | json.loads(saved.read_text())
                self.apply_editors(editors, values)
            saved = self.root / "editor-registration.json"
            if saved.exists():
                values = data["registry_original"] | json.loads(saved.read_text())
                self.apply_registries(registries, values)
            values = {"DESKTOP_THEME_ROOT": str(self.root)}
            if self.profile == "sekaipop":
                values["SEKAIPOP_THEME_CONFIG"] = str(self.root)
            reload_classicui()
            yield values
        finally:
            self.recover(save=True)


def wallpaper_backend(name, requested=None):
    # Older login entries still select the policy of their own profile.
    backend = requested or ("skwd-wall" if name in SKWD_PROFILES else "native")
    if backend not in ("native", "skwd-wall"):
        raise ValueError(f"Unsupported wallpaper backend: {backend}")
    if name == "dms-niri" and backend != "native":
        raise ValueError("Dux Shell requires its native wallpaper renderer")
    if name == "sekaipop" and backend != "native":
        raise ValueError("SekaiPop requires its native renderer for parallax and transitions")
    return backend


@contextmanager
def wallpaper_session(name, backend):
    """Publish policy; compositor-ready hooks start the opted-in renderer.

    Called only after the session/transition locks and compositor exclusion
    check. Never start a Wayland client here: the new compositor has not
    published its socket yet. The existing desktop-ready hooks do that.
    """
    def systemctl(*args, check=True):
        return subprocess.run(["systemctl", "--user", *args], check=check, timeout=30)

    prepared = False
    try:
        with prepare_session(os.environ):
            systemctl("stop", *WALLPAPER_UNITS)
            prepared = True
            systemctl("set-environment", f"DESKTOP_PROFILE={name}",
                      f"DESKTOP_WALLPAPER_BACKEND={backend}")
        yield {"DESKTOP_PROFILE": name, "DESKTOP_WALLPAPER_BACKEND": backend}
    finally:
        # Keep the policy valid until all wallpaper children have stopped.
        # Even a failed compositor launch must release the previous renderer.
        if prepared:
            try:
                systemctl("stop", *WALLPAPER_UNITS, check=False)
            finally:
                systemctl("unset-environment", "DESKTOP_WALLPAPER_BACKEND", "DESKTOP_PROFILE", check=False)


class Profiles:
    def __init__(self, home=None):
        self.home = Path(home or Path.home())
        self.config = self.home / ".config"
        self.root = self.config / "desktop-profiles"
        self.state = self.home / ".local/state/desktop-profiles"
        self.registry = json.loads((self.root / "profiles.json").read_text())

    def profile(self, name):
        if name not in self.registry:
            raise ValueError(f"Unknown desktop profile: {name}")
        return self.registry[name]

    def links(self, name):
        profile = self.profile(name)
        result = {}
        for app in profile["links"]:
            if app not in ("niri", "hypr", "noctalia", "kitty-nyxuri"):
                raise ValueError(f"Unsupported configuration entry: {app}")
            target = self.root / name / app
            if target.is_symlink() or not target.is_dir():
                raise ValueError(f"Profile configuration must be an installed directory: {target}")
            if target.resolve() != target.absolute():
                raise ValueError(f"Profile storage must not point into another directory: {target}")
            result[self.config / app] = target
        main = self.root / name / profile["compositor"]
        entry = "config.kdl" if profile["compositor"] == "niri" else "hyprland.lua"
        if profile["compositor"] == "pleamar":
            main = self.root / name / "theme/pleamar/wm"
            entry = "session.plm"
        if not (main / entry).is_file():
            raise ValueError(f"Missing compositor configuration: {main / entry}")
        return result

    @contextmanager
    def lock(self, name, blocking=True):
        self.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        path = self.state / (name + ".lock")
        with path.open("a") as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
            except BlockingIOError:
                raise ValueError("Another desktop login or maintenance operation is in progress") from None
            yield

    def compositors(self):
        found = []
        for directory in Path("/proc").iterdir():
            if not directory.name.isdigit():
                continue
            try:
                if directory.stat().st_uid != os.getuid():
                    continue
                comm = (directory / "comm").read_text().strip()
                if comm in ("niri", "Hyprland", "pleamar-wm"):
                    found.append((int(directory.name), comm))
            except (OSError, ValueError):
                continue
        return found

    @staticmethod
    def replace_link(path, target):
        if path.exists() and not path.is_symlink():
            raise ValueError(f"Refusing to replace an ordinary directory: {path}")
        temporary = path.with_name(f".{path.name}.desktop-profile-{os.getpid()}")
        try:
            temporary.symlink_to(os.path.relpath(target, path.parent))
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)

    def snapshot(self, links):
        result = {}
        for path in links:
            if not path.is_symlink():
                raise ValueError(f"Configuration entry has not been migrated: {path}")
            target = path.resolve()
            if not target.is_relative_to(self.root.resolve()):
                raise ValueError(f"Configuration link is not managed by desktop-profile: {path}")
            result[path] = target
        return result

    def restore(self, snapshot):
        for path, target in snapshot.items():
            self.replace_link(path, target)

    def select(self, name):
        links = self.links(name)
        previous = self.snapshot(links)
        try:
            for path, target in links.items():
                if path.resolve() != target:
                    self.replace_link(path, target)
        except BaseException:
            self.restore(previous)
            raise
        return previous

    def guard(self, name):
        for path, target in self.links(name).items():
            if not path.is_symlink() or path.resolve() != target:
                raise ValueError(
                    f"{path} is not selected for {name}. Use desktop-profile maintain {name} -- COMMAND "
                    "from that desktop or a TTY; maintenance will not write another desktop's configuration."
                )
        self.verify_theme_contract(name)

    def verify_theme_contract(self, name):
        source = self.profile(name).get("source")
        if not source:
            raise ValueError(f"{name}: missing personal source checkout; cannot verify theme update safety")
        verify_contract(name, Path(source))

    def theme_path(self, name, path):
        path = Path(path).absolute()
        journal = self.state / "theme-session/journal.json"
        if not journal.exists() or json.loads(journal.read_text()).get("profile") != name:
            raise ValueError("Theme directory updates require the selected managed theme session")
        for canonical, target in ThemeSession(self.home, name).bindings:
            if path == canonical and canonical.is_symlink() and canonical.resolve() == target \
                    and target.is_dir() and target.absolute() == target.resolve():
                return target
        raise ValueError(f"Not a managed {name} theme directory: {path}")

    def check_change(self, name):
        compositor = self.profile(name)["compositor"]
        expected = {"niri": "niri", "hypr": "Hyprland", "pleamar": "pleamar-wm"}[compositor]
        changing = any(path.resolve() != target for path, target in self.links(name).items())
        if changing and any(comm == expected for _, comm in self.compositors()):
            raise ValueError(f"A {expected} session is running; log out before selecting a different {compositor} configuration")

    def maintain(self, name, command):
        if not command:
            raise ValueError("Maintenance requires a command after --")
        with self.lock("transition", blocking=False):
            active = self.check_theme_maintenance(name)
            previous = self.select(name)
            env = dict(os.environ, DESKTOP_PROFILE_MAINTENANCE=name, DESKTOP_PROFILE=name)
            env.pop("SEKAIPOP_THEME_CONFIG", None)
            env["DESKTOP_THEME_ROOT"] = str(self.root / name / "theme")
            if name == "sekaipop":
                env["SEKAIPOP_THEME_CONFIG"] = env["DESKTOP_THEME_ROOT"]
            try:
                with ExitStack() as lifetime:
                    if not active:
                        env.update(lifetime.enter_context(ThemeSession(self.home, name).activate()))
                    status = subprocess.run(command, env=env).returncode
                    self.verify_theme_contract(name)
                    return status
            finally:
                self.restore(previous)

    def check_theme_maintenance(self, name):
        self.check_change(name)
        self.verify_theme_contract(name)
        active = self.compositors()
        journal = self.state / "theme-session/journal.json"
        if active and (not journal.exists() or json.loads(journal.read_text()).get("profile") != name):
            raise ValueError("Theme maintenance requires this profile's managed login; log out before updating another desktop")
        return bool(active)

    def run(self, name, command=None, requested_backend=None):
        profile = self.profile(name)
        backend = wallpaper_backend(name, requested_backend)
        with self.lock("session", blocking=False):
            # Enter wallpaper policy only after refusing an existing desktop.
            # Exit it before releasing the session lock, including on failure.
            lifetime = ExitStack()
            try:
                return self._run_session(name, command, profile, backend, lifetime)
            finally:
                # Installation also uses this lock: a profile update must not
                # swap theme storage halfway through restoring shared paths.
                with self.lock("transition"):
                    lifetime.close()

    def _run_session(self, name, command, profile, backend, lifetime):
        with self.lock("transition", blocking=False):
            if self.compositors():
                raise ValueError("A graphical session is still running for this user; log out before starting another desktop")
            if name == "dms-niri":
                # Reject an unsafe source before selecting links or moving theme files.
                self.verify_theme_contract(name)
            ThemeSession(self.home).recover()
            previous = self.select(name)
            env = dict(os.environ)
            env["XDG_CONFIG_HOME"] = str(self.config)
            env["DESKTOP_PROFILE"] = name
            env.pop("SEKAIPOP_THEME_CONFIG", None)
            env.pop("DESKTOP_THEME_ROOT", None)
            if name == "nyxuri":
                env["NOCTALIA_CONFIG_HOME"] = str(self.config)
                env["NOCTALIA_STATE_HOME"] = str(self.home / ".local/state/nyxuri-desktop/noctalia")
            else:
                for variable in ("NOCTALIA_CONFIG_HOME", "NOCTALIA_STATE_HOME", "KITTY_CONFIG_DIRECTORY"):
                    env.pop(variable, None)
            argv = command or [arg.replace("{home}", str(self.home)) for arg in profile["start"]]
            try:
                env.update(lifetime.enter_context(wallpaper_session(name, backend)))
                if name in THEME_PROFILES:
                    env.update(lifetime.enter_context(ThemeSession(self.home, name).activate()))
                process = subprocess.Popen(argv, env=env)
            except BaseException:
                self.restore(previous)
                raise
        status = process.wait()
        # A failed startup must not strand the next login on its configuration.
        if status and not self.compositors():
            with self.lock("transition"):
                self.restore(previous)
        return status

    def status(self):
        entries = {}
        for name, profile in self.registry.items():
            entries[name] = {
                "compositor": profile["compositor"],
                "selected": all(path.is_symlink() and path.resolve() == target for path, target in self.links(name).items()),
                "directory": str(self.root / name),
                "source": profile.get("source"),
                "wallpaper_backend": wallpaper_backend(name),
            }
        return {"profiles": entries, "running_compositors": self.compositors()}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("status")
    path = sub.add_parser("path")
    path.add_argument("profile")
    path.add_argument("app", nargs="?")
    guard = sub.add_parser("guard")
    guard.add_argument("profile")
    theme = sub.add_parser("theme-path")
    theme.add_argument("profile")
    theme.add_argument("path")
    for action in ("run", "maintain"):
        command = sub.add_parser(action)
        if action == "run":
            command.add_argument("--wallpaper-backend", choices=("native", "skwd-wall"))
        command.add_argument("profile")
        command.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    try:
        profiles = Profiles()
        if args.action == "status":
            print(json.dumps(profiles.status(), indent=2, ensure_ascii=False))
        elif args.action == "path":
            profile = profiles.profile(args.profile)
            if args.app and args.app not in profile["links"]:
                raise ValueError("Application is not owned by this desktop profile")
            print(profiles.root / args.profile / (args.app or ""))
        elif args.action == "guard":
            profiles.guard(args.profile)
        elif args.action == "theme-path":
            print(profiles.theme_path(args.profile, args.path))
        else:
            command = args.command[1:] if args.command[:1] == ["--"] else args.command
            if args.action == "run":
                return profiles.run(args.profile, command or None, args.wallpaper_backend)
            return profiles.maintain(args.profile, command or None)
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"desktop-profile: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
