#!/usr/bin/env python3
"""Start a Waydroid Flex window without selecting the user's physical phone."""

import os
import fcntl
import json
import re
import subprocess
import sys
import time
from pathlib import Path


def run(command, timeout=12):
    return subprocess.run(command, text=True, capture_output=True, timeout=timeout)


def status():
    return run(["waydroid", "status"]).stdout


def fail(message):
    print("WAYDROID_FLEX_ERROR: " + message, flush=True)
    subprocess.run(["notify-send", "Waydroid Flex", message], check=False)
    raise SystemExit(1)


def start_session():
    log = Path.home() / ".cache/illogical-impulse/phone/waydroid-session.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a") as output:
        subprocess.Popen(["waydroid", "session", "start"], stdin=subprocess.DEVNULL,
                         stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
    for _ in range(45):
        time.sleep(1)
        if "Session:\tRUNNING" in status():
            return
    fail("Waydroid session did not start; see " + str(log))


def wake_and_address():
    # Closing Waydroid's native window freezes the container, but does not
    # stop its session. Wake it directly so scrcpy needs no native window.
    current = status()
    if "Container:\tFROZEN" in current:
        wake = run(["busctl", "--system", "call", "id.waydro.Container",
                    "/ContainerManager", "id.waydro.ContainerManager", "Unfreeze"])
        if wake.returncode:
            fail("Could not wake Waydroid: " + (wake.stderr.strip() or wake.stdout.strip()))
    for _ in range(20):
        current = status()
        if "Container:\tRUNNING" in current:
            break
        time.sleep(1)
    else:
        fail("Waydroid container is not running")

    match = re.search(r"^IP address:\s*(\d+\.\d+\.\d+\.\d+)\s*$", current, re.M)
    if not match:
        fail("Waydroid did not report an ADB address")
    return match.group(1) + ":5555"


def connect_adb(serial):
    unreachable = False
    for _ in range(10):
        attempt = run(["adb", "connect", serial], timeout=5)
        unreachable |= "No route to host" in (attempt.stdout + attempt.stderr)
        devices = run(["adb", "devices"], timeout=5).stdout
        if re.search(r"^" + re.escape(serial) + r"\s+device\s*$", devices, re.M):
            return True, unreachable
        if re.search(r"^" + re.escape(serial) + r"\s+unauthorized\s*$", devices, re.M):
            fail("Allow the ADB debugging prompt in Waydroid, then try again")
        time.sleep(1)
    return False, unreachable


def select_hyprland_instance():
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return
    instances = run(["hyprctl", "instances", "-j"], timeout=2)
    if instances.returncode:
        return
    try:
        active = json.loads(instances.stdout)
    except (ValueError, TypeError):
        return
    if len(active) == 1:
        os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = active[0]["instance"]


def focus_flex_window(pid=None):
    clients = run(["hyprctl", "clients", "-j"], timeout=2)
    if clients.returncode:
        return False
    try:
        windows = json.loads(clients.stdout)
    except (ValueError, TypeError):
        return False
    window = next((item for item in windows
                   if item.get("class") == "scrcpy" and item.get("title") == "Waydroid Flex"
                   and (pid is None or item.get("pid") == pid)), None)
    if not window or not window.get("address"):
        return False
    focused = run(["hyprctl", "dispatch", 'hl.dsp.focus{window="address:'
                   + window["address"] + '"}'], timeout=2)
    return focused.stdout.strip().lower() == "ok"


def main():
    if not os.environ.get("WAYLAND_DISPLAY") or not os.environ.get("XDG_RUNTIME_DIR"):
        fail("Wayland desktop session is unavailable")
    select_hyprland_instance()
    bit_rate = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else "4M"
    if not re.fullmatch(r"[1-9][0-9]*[KM]?", bit_rate):
        fail("Invalid video bitrate; use values such as 4M or 800K")

    lock_path = Path(os.environ["XDG_RUNTIME_DIR"]) / "waydroid-flex.lock"
    lock_fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        if not focus_flex_window():
            subprocess.run(["notify-send", "Waydroid Flex", "Waydroid Flex is starting"], check=False)
        return

    if "Session:\tRUNNING" not in status():
        start_session()
    serial = wake_and_address()
    connected, unreachable = connect_adb(serial)
    if not connected and unreachable:
        print("WAYDROID_FLEX_RECOVERING_NETWORK", flush=True)
        stopped = run(["waydroid", "session", "stop"], timeout=25)
        if stopped.returncode:
            fail("Could not restart Waydroid after a network failure")
        start_session()
        serial = wake_and_address()
        connected, _ = connect_adb(serial)
    if not connected:
        fail("Waydroid ADB did not become available")

    print("WAYDROID_FLEX_READY", flush=True)
    mirror = subprocess.Popen(["scrcpy", "-s", serial,
                               "--new-display=540x960/180", "--flex-display", "--no-audio",
                               "--video-encoder=c2.android.avc.encoder",
                               "--video-bit-rate=" + bit_rate, "--max-fps=60",
                               "--start-app=com.android.settings", "--window-title=Waydroid Flex"])
    for _ in range(30):
        if mirror.poll() is not None:
            break
        if focus_flex_window(mirror.pid):
            break
        time.sleep(0.5)
    raise SystemExit(mirror.wait())


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.TimeoutExpired) as exc:
        fail(str(exc))
