#!/usr/bin/env python3
"""Select installed desktop configurations before starting a login session."""
import argparse
from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


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
                if comm in ("niri", "Hyprland"):
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

    def check_change(self, name):
        compositor = self.profile(name)["compositor"]
        expected = "niri" if compositor == "niri" else "Hyprland"
        changing = any(path.resolve() != target for path, target in self.links(name).items())
        if changing and any(comm == expected for _, comm in self.compositors()):
            raise ValueError(f"A {expected} session is running; log out before selecting a different {compositor} configuration")

    def maintain(self, name, command):
        if not command:
            raise ValueError("Maintenance requires a command after --")
        with self.lock("transition", blocking=False):
            self.check_change(name)
            previous = self.select(name)
            env = dict(os.environ, DESKTOP_PROFILE_MAINTENANCE=name)
            try:
                return subprocess.run(command, env=env).returncode
            finally:
                self.restore(previous)

    def run(self, name, command=None):
        profile = self.profile(name)
        with self.lock("session", blocking=False):
            with self.lock("transition", blocking=False):
                if self.compositors():
                    raise ValueError("A graphical session is still running for this user; log out before starting another desktop")
                previous = self.select(name)
                env = dict(os.environ)
                env["XDG_CONFIG_HOME"] = str(self.config)
                env["DESKTOP_PROFILE"] = name
                if name == "nyxuri":
                    env["NOCTALIA_CONFIG_HOME"] = str(self.config)
                    env["NOCTALIA_STATE_HOME"] = str(self.home / ".local/state/nyxuri-desktop/noctalia")
                else:
                    for variable in ("NOCTALIA_CONFIG_HOME", "NOCTALIA_STATE_HOME", "KITTY_CONFIG_DIRECTORY"):
                        env.pop(variable, None)
                argv = command or [arg.replace("{home}", str(self.home)) for arg in profile["start"]]
                try:
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
    for action in ("run", "maintain"):
        command = sub.add_parser(action)
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
        else:
            command = args.command[1:] if args.command[:1] == ["--"] else args.command
            return getattr(profiles, args.action)(args.profile, command or None)
        return 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"desktop-profile: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
