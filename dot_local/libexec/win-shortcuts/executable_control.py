#!/usr/bin/env -S python3 -S
"""Build or control the process-local SDL3 shortcut policy used by win."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import socket
import stat
import struct
import subprocess
import sys
import tempfile


def runtime_directory():
    configured = os.environ.get("WIN_SHORTCUTS_DIR")
    if configured:
        return Path(configured)
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        raise RuntimeError("XDG_RUNTIME_DIR is missing")
    return Path(runtime) / "win-shortcuts"


def private_directory(directory):
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = directory.lstat()
    if (not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid()
            or stat.S_IMODE(info.st_mode) != 0o700):
        raise RuntimeError(f"Not a private owned directory: {directory}")


def build_library():
    source = Path(__file__).resolve().with_name("grab.c")
    flags = shlex.split(subprocess.check_output(
        ["pkg-config", "--cflags", "--libs", "sdl3"], text=True))
    version = subprocess.check_output(["pkg-config", "--modversion", "sdl3"])
    digest = hashlib.sha256(source.read_bytes() + version + repr(flags).encode()).hexdigest()[:20]
    cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "win-shortcuts"
    private_directory(cache)
    library = cache / f"grab-{digest}.so"
    if library.exists():
        info = library.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid():
            raise RuntimeError("Unsafe cached shortcut library")
        return library
    with tempfile.TemporaryDirectory(prefix="build-", dir=cache) as temporary:
        target = Path(temporary) / "grab.so"
        subprocess.run(["cc", "-std=c11", "-O2", "-fPIC", "-shared", "-Wall", "-Wextra",
                        "-Werror", "-Wl,-z,defs", str(source), "-o", str(target),
                        *flags, "-ldl"], check=True)
        target.chmod(0o600)
        os.replace(target, library)
    return library


def request(pid, command):
    directory = runtime_directory()
    private_directory(directory)
    path = directory / f"{pid}.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET) as client:
        client.settimeout(2)
        client.connect(str(path))
        peer = struct.unpack("3i", client.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
        if peer[0] != pid or peer[1] != os.getuid():
            raise RuntimeError("Shortcut endpoint does not belong to the focused process")
        client.sendall(command.encode())
        response = client.recv(128).decode().strip()
    if response not in {"local 0", "remote 0", "remote 1"}:
        raise RuntimeError(f"Shortcut control rejected: {response}")
    if command in {"toggle", "remote"} and response == "remote 0":
        raise RuntimeError("Remote mode was requested but SDL did not grab the keyboard")
    return response


def focused_target():
    result = subprocess.run(["niri", "msg", "-j", "focused-window"],
                            check=True, capture_output=True, text=True, timeout=3)
    window = json.loads(result.stdout)
    if window and window.get("app_id") == "com.freerdp.client.sdl3":
        pid = window.get("pid")
        if isinstance(pid, int) and pid > 0:
            return pid
    return None


def notify(message):
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "-a", "win-shortcuts", "-t", "1600",
                        "-h", "string:x-canonical-private-synchronous:win-shortcuts",
                        "Windows 快捷键", message], check=False, timeout=3)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "toggle", "status", "local", "remote"))
    parser.add_argument("--pid", type=int, help="Explicit target for diagnostics")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()
    try:
        if args.command == "build":
            print(build_library())
            return 0
        pid = args.pid if args.pid is not None else focused_target()
        if pid is None:
            if args.command == "toggle":
                subprocess.run(["niri", "msg", "action", "toggle-keyboard-shortcuts-inhibit"],
                               check=True, timeout=3)
                return 0
            raise RuntimeError("Focus the Windows client first")
        if pid <= 0:
            raise RuntimeError("Invalid client PID")
        try:
            response = request(pid, args.command)
        except (FileNotFoundError, ConnectionRefusedError) as error:
            raise RuntimeError("请关闭旧的 FreeRDP 窗口，再运行 win 以加载快捷键控制") from error
        print(response)
        if args.command != "status" and not args.quiet:
            notify("远程接管 · Super+Esc 返回本机" if response.startswith("remote")
                   else "本机快捷键 · Super+Esc 交给 Windows")
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"win-shortcuts: {error}", file=sys.stderr)
        if not args.quiet:
            notify(str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
