"""Exercise the real preload boundary without a compositor or RDP credentials."""
import os
from pathlib import Path
import shlex
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "dot_local/libexec/win-shortcuts/grab.c"
CONTROLLER = SOURCE.with_name("executable_control.py")

FAKE_SDL = r'''
#define _DEFAULT_SOURCE
#include <SDL3/SDL.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
static int window;
static bool grabbed;
SDL_Window *SDL_GetKeyboardFocus(void) { return (SDL_Window *)&window; }
SDL_Window *SDL_GetWindowFromID(SDL_WindowID id) {
    return id == 1 ? (SDL_Window *)&window : NULL;
}
SDL_WindowID SDL_GetWindowID(SDL_Window *w) { return w ? 1 : 0; }
bool SDL_GetWindowKeyboardGrab(SDL_Window *w) { (void)w; return grabbed; }
bool SDL_SetWindowKeyboardGrab(SDL_Window *w, bool value) {
    (void)w; grabbed = value; return true;
}
void SDL_DestroyWindow(SDL_Window *w) { (void)w; }
bool SDL_PollEvent(SDL_Event *event) { (void)event; return false; }
bool SDL_WaitEventTimeout(SDL_Event *event, Sint32 timeout) {
    (void)event;
    /* FreeRDP repeatedly requests grabs on pointer leave and re-entry. */
    SDL_SetWindowKeyboardGrab(SDL_GetKeyboardFocus(), false);
    SDL_SetWindowKeyboardGrab(SDL_GetKeyboardFocus(), true);
    const char *path = getenv("TEST_STATE_FILE");
    if (path) {
        int fd = open(path, O_CREAT | O_WRONLY, 0600);
        if (fd >= 0) { char value = grabbed ? '1' : '0'; (void)write(fd, &value, 1); close(fd); }
    }
    usleep((useconds_t)(timeout > 0 ? timeout : 1) * 1000);
    return false;
}
'''
RUNNER = r'''
#include <SDL3/SDL.h>
#include <stdio.h>
int main(void) {
    SDL_SetWindowKeyboardGrab(SDL_GetKeyboardFocus(), true);
    printf("%d\n", SDL_GetWindowKeyboardGrab(SDL_GetKeyboardFocus()));
    fflush(stdout);
    for (;;) SDL_WaitEventTimeout(NULL, 20);
}
'''


class GrabTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        cflags = shlex.split(subprocess.check_output(
            ["pkg-config", "--cflags", "sdl3"], text=True))
        (self.root / "fake.c").write_text(FAKE_SDL)
        (self.root / "runner.c").write_text(RUNNER)
        subprocess.run(["cc", "-Wall", "-Wextra", "-Werror", "-fPIC", "-shared",
                        *cflags, str(self.root / "fake.c"), "-o",
                        str(self.root / "libfake-sdl.so")], check=True)
        subprocess.run(["cc", *cflags, str(self.root / "runner.c"),
                        "-L" + str(self.root), "-Wl,-rpath," + str(self.root),
                        "-lfake-sdl", "-o", str(self.root / "runner")], check=True)
        self.env = os.environ.copy()
        self.env.pop("LD_PRELOAD", None)
        self.env["WIN_SHORTCUTS_DIR"] = str(self.root / "runtime")
        self.env["TEST_STATE_FILE"] = str(self.root / "grabbed")
        if SOURCE.exists():
            flags = shlex.split(subprocess.check_output(
                ["pkg-config", "--cflags", "--libs", "sdl3"], text=True))
            lib = self.root / "grab.so"
            subprocess.run(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror",
                            "-fPIC", "-shared", str(SOURCE), "-o", str(lib),
                            *flags, "-ldl"], check=True)
            self.env["LD_PRELOAD"] = str(lib)
        self.child = subprocess.Popen([self.root / "runner"], env=self.env,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      text=True)

    def tearDown(self):
        self.child.terminate()
        self.child.communicate(timeout=3)
        self.temp.cleanup()

    def request(self, command):
        path = self.root / "runtime" / f"{self.child.pid}.sock"
        with socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET) as client:
            client.settimeout(2)
            client.connect(str(path))
            client.sendall(command.encode())
            return client.recv(128).decode().strip()

    def test_defaults_to_local_despite_application_grab_request(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0",
                         "FreeRDP must not acquire host shortcuts automatically")

    def test_toggle_survives_repeated_pointer_entry_and_release(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0")
        self.assertEqual(self.request("status"), "local 0")
        self.assertEqual(self.request("toggle"), "remote 1")
        time.sleep(0.1)
        self.assertEqual(self.request("status"), "remote 1")
        self.assertEqual(self.request("toggle"), "local 0")
        time.sleep(0.1)
        self.assertEqual(self.request("status"), "local 0")
        self.assertEqual(self.request("toggle"), "remote 1")

    def test_controller_confirms_the_target_pid_and_reports_actual_mode(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0")
        result = subprocess.run([sys.executable, CONTROLLER, "toggle", "--pid",
                                 str(self.child.pid), "--quiet"], env=self.env,
                                capture_output=True, text=True, timeout=3)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "remote 1")
        self.assertEqual(self.request("status"), "remote 1")

    def test_losing_control_endpoint_releases_the_keyboard(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0")
        self.assertEqual(self.request("toggle"), "remote 1")
        (self.root / "runtime" / f"{self.child.pid}.sock").unlink()
        # The fixture's setter runs every wait slice; report its effective flag
        # through the still-open process using an independent debug-only file.
        time.sleep(0.1)
        self.assertEqual((self.root / "grabbed").read_text(), "0")

    def test_two_instances_do_not_share_the_selected_mode(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0")
        second = subprocess.Popen([self.root / "runner"], env=self.env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            assert second.stdout is not None
            self.assertEqual(second.stdout.readline().strip(), "0")
            self.assertEqual(self.request("toggle"), "remote 1")
            result = subprocess.run([sys.executable, CONTROLLER, "status", "--pid",
                                     str(second.pid), "--quiet"], env=self.env,
                                    capture_output=True, text=True, timeout=3)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), "local 0")
        finally:
            second.terminate()
            second.communicate(timeout=3)

    def test_controller_rejects_a_socket_owned_by_another_pid(self):
        assert self.child.stdout is not None
        self.assertEqual(self.child.stdout.readline().strip(), "0")
        alias = self.child.pid + 10000000
        (self.root / "runtime" / f"{alias}.sock").symlink_to(f"{self.child.pid}.sock")
        result = subprocess.run([sys.executable, CONTROLLER, "toggle", "--pid",
                                 str(alias), "--quiet"], env=self.env,
                                capture_output=True, text=True, timeout=3)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not belong", result.stderr)
        self.assertEqual(self.request("status"), "local 0")


if __name__ == "__main__":
    unittest.main()
