#!/usr/bin/env python3
"""Opt-in live SDL/Niri probe; only injects keys into its own temporary window."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time
from evdev import UInput, ecodes

PROGRAM = r'''
#include <SDL3/SDL.h>
#include <stdio.h>
int main(void) {
    SDL_SetAppMetadata("Shortcut verification", "1", "com.freerdp.client.sdl3");
    if (!SDL_Init(SDL_INIT_VIDEO)) return 2;
    SDL_Window *window = SDL_CreateWindow("Shortcut policy verification", 480, 180, 0);
    if (!window) return 3;
    SDL_Surface *surface = SDL_GetWindowSurface(window);
    if (!surface) return 4;
    SDL_FillSurfaceRect(surface, NULL, SDL_MapSurfaceRGB(surface, 40, 45, 55));
    if (!SDL_UpdateWindowSurface(window)) return 5;
    SDL_SetWindowKeyboardGrab(window, true);
    puts("ready"); fflush(stdout);
    Uint64 end = SDL_GetTicks() + 20000, next = 0;
    while (SDL_GetTicks() < end) {
        SDL_Event event;
        if (SDL_WaitEventTimeout(&event, 20)) {
            if (event.type == SDL_EVENT_QUIT) break;
            if (event.type == SDL_EVENT_KEY_DOWN &&
                (event.key.key == SDLK_C || event.key.key == SDLK_Q)) {
                printf("key %c\n", event.key.key == SDLK_C ? 'c' : 'q'); fflush(stdout);
            }
        }
        if (SDL_GetTicks() >= next) {
            /* Exercise FreeRDP's automatic leave/enter calls on the real SDL backend. */
            SDL_SetWindowKeyboardGrab(window, false);
            SDL_SetWindowKeyboardGrab(window, true);
            next = SDL_GetTicks() + 70;
        }
    }
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
'''


def query(name):
    return json.loads(subprocess.check_output(["niri", "msg", "-j", name], text=True))


def focus(window_id):
    subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(window_id)],
                   check=True, stdout=subprocess.DEVNULL)
    time.sleep(0.12)
    window = query("focused-window")
    if not window or window["id"] != window_id:
        raise RuntimeError("Probe did not gain focus; refusing keyboard injection")


def main():
    if not os.environ.get("NIRI_SOCKET") or not os.environ.get("WAYLAND_DISPLAY"):
        raise RuntimeError("This opt-in probe requires the current Niri Wayland session")
    helper = Path.home() / ".local/libexec/win-shortcuts/control.py"
    library = subprocess.check_output([helper, "build"], text=True).strip()
    original = query("focused-window")
    with tempfile.TemporaryDirectory(prefix="win-shortcuts-live-") as temporary:
        root = Path(temporary)
        source = root / "probe.c"
        source.write_text(PROGRAM)
        binary = root / "probe"
        flags = shlex.split(subprocess.check_output(
            ["pkg-config", "--cflags", "--libs", "sdl3"], text=True))
        subprocess.run(["cc", "-Wall", "-Wextra", "-Werror", str(source), "-o", str(binary),
                        *flags], check=True)
        env = os.environ.copy()
        env.update(SDL_VIDEO_DRIVER="wayland", LD_PRELOAD=library,
                   WIN_SHORTCUTS_DIR=str(Path(os.environ["XDG_RUNTIME_DIR"]) / "win-shortcuts"))
        log = root / "events.log"
        error_log = root / "errors.log"
        with log.open("w") as output, error_log.open("w") as errors:
            keyboard = UInput({ecodes.EV_KEY: list(range(1, 249))},
                              name="win-shortcuts-test-only")
            child = subprocess.Popen([binary], env=env, stdout=output, stderr=errors)
            probe_id = None
            try:
                deadline = time.monotonic() + 4
                while time.monotonic() < deadline:
                    matches = [w for w in query("windows") if w.get("pid") == child.pid]
                    if matches:
                        probe_id = matches[0]["id"]
                        break
                    if child.poll() is not None:
                        raise RuntimeError(error_log.read_text())
                    time.sleep(0.05)
                if probe_id is None:
                    raise RuntimeError("Probe window did not appear")
                focus(probe_id)
                time.sleep(0.3)

                def mode(expected):
                    until = time.monotonic() + 2
                    result = "no reply"
                    while time.monotonic() < until:
                        result = subprocess.check_output(
                            [helper, "status", "--pid", str(child.pid), "--quiet"], text=True).strip()
                        if result == expected:
                            return
                        time.sleep(0.04)
                    raise RuntimeError(f"Expected {expected}, got {result}")

                def key(name, super_key=True):
                    current = query("focused-window")
                    if not current or current["id"] != probe_id:
                        raise RuntimeError("Focus changed; refusing keyboard injection")
                    code = {"c": ecodes.KEY_C, "q": ecodes.KEY_Q,
                            "Escape": ecodes.KEY_ESC}[name]
                    try:
                        if super_key:
                            keyboard.write(ecodes.EV_KEY, ecodes.KEY_LEFTMETA, 1)
                            keyboard.syn()
                            time.sleep(0.03)
                        keyboard.write(ecodes.EV_KEY, code, 1)
                        keyboard.syn()
                        time.sleep(0.03)
                    finally:
                        keyboard.write(ecodes.EV_KEY, code, 0)
                        keyboard.write(ecodes.EV_KEY, ecodes.KEY_LEFTMETA, 0)
                        keyboard.syn()
                    time.sleep(0.12)

                def count(name):
                    return log.read_text().splitlines().count(f"key {name}")

                mode("local 0")
                key("c", False)
                if count("c") != 1:
                    raise RuntimeError("Positive input control did not reach the probe")
                key("c")
                if count("c") != 1:
                    raise RuntimeError("Local mode leaked the host shortcut")
                key("Escape")
                mode("remote 1")
                key("c")
                if count("c") != 2:
                    raise RuntimeError("Remote mode did not receive Super+C")
                key("q")
                if child.poll() is not None or count("q") != 1:
                    raise RuntimeError("Super+Q did not stay in the remote client")
                if original:
                    focus(original["id"])
                    focus(probe_id)
                mode("remote 1")
                key("c")
                if count("c") != 3:
                    raise RuntimeError("Remote ownership did not survive refocus")
                key("Escape")
                mode("local 0")
                key("c")
                if count("c") != 3:
                    raise RuntimeError("Released mode re-acquired the host shortcut")
                if original:
                    focus(original["id"])
                    focus(probe_id)
                mode("local 0")
                key("Escape")
                mode("remote 1")
                key("Escape")
                mode("local 0")
                print(json.dumps({"default_local": True, "real_hotkey_toggle": True,
                                  "local_shortcut_stays_host_side": True,
                                  "remote_shortcut_reaches_client": True,
                                  "remote_super_q_does_not_close_client": True,
                                  "mode_survives_refocus_and_auto_grab_calls": True,
                                  "released_mode_stays_local": True}, indent=2))
            finally:
                for code in (ecodes.KEY_C, ecodes.KEY_Q, ecodes.KEY_ESC, ecodes.KEY_LEFTMETA):
                    keyboard.write(ecodes.EV_KEY, code, 0)
                keyboard.syn()
                keyboard.close()
                child.terminate()
                try:
                    child.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=2)
                current = query("focused-window")
                if original and (not current or current["id"] == probe_id):
                    focus(original["id"])


if __name__ == "__main__":
    main()
