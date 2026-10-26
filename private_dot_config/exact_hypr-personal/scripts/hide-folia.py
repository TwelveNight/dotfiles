#!/usr/bin/env python3
"""Hide only a captured Folia player through its own PID-verified tray."""
import json
import re
import subprocess
import sys


def query(name):
    return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True, timeout=3))


def bus_call(*args):
    result = subprocess.check_output([
        "busctl", "--user", "--json=short", "--timeout=2", *map(str, args),
    ], text=True, timeout=3)
    return json.loads(result)["data"] if result.strip() else []


def is_player(window):
    return window.get("class") == "folia-major" and window.get("title") == "Folia"


def hide_folia(captured):
    window = next((w for w in query("clients") if w.get("address") == captured["address"]), None)
    if window is None:
        return
    if not is_player(window) or window.get("pid") != captured.get("pid"):
        raise RuntimeError("Folia window changed; leaving it running")
    pid = window.get("pid")
    if not isinstance(pid, int) or pid <= 0:
        raise RuntimeError("Folia window has no valid process ID")
    dbus = ("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus")
    names = bus_call("call", *dbus, "ListNames")[0]
    services = [name for name in names
                if name.startswith(f"org.freedesktop.StatusNotifierItem-{pid}-")]
    if len(services) != 1:
        raise RuntimeError("Cannot identify Folia's tray; leaving the player running")
    # Pin the unique D-Bus owner and check the actual player PID before clicking.
    owner = bus_call("call", *dbus, "GetNameOwner", "s", services[0])[0]
    if bus_call("call", *dbus, "GetConnectionUnixProcessID", "s", owner)[0] != pid:
        raise RuntimeError("Folia tray process does not match the captured window")
    menu = bus_call("get-property", owner, "/StatusNotifierItem", "org.kde.StatusNotifierItem", "Menu")
    target = (owner, menu, "com.canonical.dbusmenu")
    layout = bus_call("call", *target, "GetLayout", "iias", 0, 1, 3, "label", "enabled", "visible")
    for item in layout[1][2]:
        item_id, props, _children = item["data"]
        label = props.get("label", {}).get("data")
        if label in {"显示窗口", "Show Window", "Tampilkan Jendela"}:
            return  # Already hidden: never toggle it back open.
        if label in {"隐藏窗口", "Hide Window", "Sembunyikan Jendela"}:
            if not props.get("enabled", {}).get("data", True) or not props.get("visible", {}).get("data", True):
                break
            bus_call("call", *target, "Event", "isvu", item_id, "clicked", "s", "", 0)
            return
    # A failed hide must never fall back to a normal close/quit.
    raise RuntimeError("Folia's hide menu is unavailable; leaving the player running")


def main(address, pid):
    if not re.fullmatch(r"0x[0-9a-fA-F]+", address) or address == "0x0":
        raise ValueError("Invalid captured window address")
    hide_folia({"address": address, "pid": int(pid)})


if __name__ == "__main__":
    try:
        main(*sys.argv[1:])
    except (OSError, ValueError, KeyError, IndexError, TypeError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"SekaiPop hide Folia: {error}", file=sys.stderr)
        sys.exit(1)
