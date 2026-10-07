"""Exercise win without starting libvirt or connecting to a real desktop."""
import json
import fcntl
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import time
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "dot_local/scripts/executable_win"


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.settings = {"state": "running", "start_ok": True,
                         "client_failures": 0, "window_delay": 0}
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.root), XDG_STATE_HOME=str(self.root / "state"),
                        PATH=f"{self.bin}:{os.environ['PATH']}",
                        TEST_ROOT=str(self.root), NIRI_SOCKET="test", WAYLAND_DISPLAY="test",
                        WIN_RDP_TIMEOUT="3", WIN_WINDOW_TIMEOUT="3", WIN_CONNECT_ATTEMPTS="1")
        self.env.pop("WIN_RDP_CLIENT", None)
        self.env.pop("SDL_VIDEO_DRIVER", None)
        self.env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
        self.script = self.root / "win"
        # Replace the existing credential configuration with harmless fixture data.
        body = SOURCE.read_text().split("# Wait for readiness", 1)[1]
        self.script.write_text("#!/bin/bash\nvmip=127.0.0.1\nwin11user=test\nwin11pass='test secret'\n# Wait for readiness" + body)
        self.script.chmod(0o755)
        self.write_command("virsh", '''import json,os,sys
from pathlib import Path
r=Path(os.environ["TEST_ROOT"])
c=json.loads((r/"settings.json").read_text())
action=sys.argv[3]
with (r/"virsh_calls").open("a") as f: f.write(action+"\\n")
if action=="domstate": print(c["state"])
elif not c["start_ok"]: sys.exit(1)
''')
        self.write_command("sdl-freerdp3", '''import json,os,signal,sys,time
from pathlib import Path
r=Path(os.environ["TEST_ROOT"])
c=json.loads((r/"settings.json").read_text())
counter=r/"attempts"
n=int(counter.read_text())+1 if counter.exists() else 1
counter.write_text(str(n))
args=os.fdopen(3).read().splitlines()
(r/"args.json").write_text(json.dumps(args))
(r/"argv.json").write_text(json.dumps(sys.argv))
(r/"driver").write_text(os.environ.get("SDL_VIDEO_DRIVER", ""))
if n <= c["client_failures"]: sys.exit(1)
(r/"pid").write_text(str(os.getpid()))
(r/"started").write_text(str(time.monotonic()))
def stop(*_):
    (r/"stopped").touch()
    sys.exit(0)
signal.signal(signal.SIGTERM,stop)
time.sleep(120)
''')
        self.write_command("niri", '''import json,os,time
from pathlib import Path
r=Path(os.environ["TEST_ROOT"])
c=json.loads((r/"settings.json").read_text())
if not (r/"pid").exists(): print("[]")
elif time.monotonic()-float((r/"started").read_text()) < c["window_delay"]: print("[]")
else: print(json.dumps([{"pid":int((r/"pid").read_text())}]))
''')
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.env["WIN_RDP_PORT"] = str(self.listener.getsockname()[1])
        self.listener.settimeout(0.2)
        self.closed = threading.Event()

    def write_command(self, name, body):
        path = self.bin / name
        path.write_text("#!/usr/bin/env python3\n" + body)
        path.chmod(0o755)

    def listen(self, delay=0):
        def serve():
            if self.closed.wait(delay):
                return
            self.listener.listen()
            while not self.closed.is_set():
                try:
                    conn, _ = self.listener.accept()
                    conn.close()
                except (socket.timeout, OSError):
                    pass
        self.thread = threading.Thread(target=serve, daemon=True)
        self.thread.start()

    def run_launcher(self):
        (self.root / "settings.json").write_text(json.dumps(self.settings))
        return subprocess.run([self.script], env=self.env, capture_output=True, text=True, timeout=25)

    def tearDown(self):
        if (self.root / "pid").exists():
            try:
                os.kill(int((self.root / "pid").read_text()), 15)
            except ProcessLookupError:
                pass
        self.closed.set()
        self.listener.close()
        if hasattr(self, "thread"):
            self.thread.join(1)
        time.sleep(0.05)
        self.temp.cleanup()

    def test_running_vm_and_private_args(self):
        self.listen()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "virsh_calls").read_text(), "domstate\n")
        self.assertIn("window is ready", result.stdout)
        self.assertEqual(json.loads((self.root / "argv.json").read_text())[1:], ["/args-from:fd:3"])
        self.assertIn("/p:test secret", json.loads((self.root / "args.json").read_text()))
        self.assertIn("+grab-keyboard", json.loads((self.root / "args.json").read_text()))
        self.assertEqual((self.root / "driver").read_text(), "wayland")
        self.assertEqual(subprocess.run(["flock", "-n", str(self.root / "state/win/launch.lock"), "true"]).returncode, 0)
        for log in (self.root / "state/win").glob("*.log"):
            self.assertEqual(log.stat().st_mode & 0o777, 0o600)

    def test_stopped_vm_starts_and_waits_for_rdp(self):
        self.settings["state"] = "shut off"
        self.listen(delay=1.2)
        start = time.monotonic()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertGreaterEqual(time.monotonic() - start, 1.2)
        self.assertEqual((self.root / "virsh_calls").read_text(), "domstate\nstart\n")

    def test_start_failure_never_connects(self):
        self.settings.update(state="shut off", start_ok=False)
        result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("start failed", result.stderr)
        self.assertFalse((self.root / "attempts").exists())

    def test_rdp_timeout_never_connects(self):
        self.env["WIN_RDP_TIMEOUT"] = "1"
        result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not become ready", result.stderr)
        self.assertFalse((self.root / "attempts").exists())

    def test_retry_client_failure(self):
        self.settings["client_failures"] = 1
        self.env["WIN_CONNECT_ATTEMPTS"] = "2"
        self.listen()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "attempts").read_text(), "2")

    def test_waits_for_window(self):
        self.settings["window_delay"] = 1.2
        self.listen()
        start = time.monotonic()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertGreaterEqual(time.monotonic() - start, 1.2)

    def test_window_timeout_stops_only_new_client(self):
        self.settings["window_delay"] = 120
        self.env["WIN_WINDOW_TIMEOUT"] = "1"
        self.listen()
        result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.root / "stopped").exists())
        self.assertEqual((self.root / "virsh_calls").read_text(), "domstate\n")

    def test_invalid_timeout(self):
        self.env["WIN_RDP_TIMEOUT"] = "0"
        result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("positive integer", result.stderr)
        self.assertFalse((self.root / "virsh_calls").exists())

    def test_paused_vm_resumes(self):
        self.settings["state"] = "paused"
        self.listen()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "virsh_calls").read_text(), "domstate\nresume\n")

    def test_hyprland_window_confirmation(self):
        self.env.pop("NIRI_SOCKET")
        self.env["HYPRLAND_INSTANCE_SIGNATURE"] = "test"
        (self.bin / "hyprctl").symlink_to(self.bin / "niri")
        self.listen()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("window is ready", result.stdout)

    def test_x11_client_fallback(self):
        self.env.pop("WAYLAND_DISPLAY")
        (self.bin / "xfreerdp3").symlink_to(self.bin / "sdl-freerdp3")
        self.listen()
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.root / "driver").read_text(), "")
        self.assertEqual(Path(json.loads((self.root / "argv.json").read_text())[0]).name, "xfreerdp3")

    def test_concurrent_launcher_is_rejected(self):
        directory = self.root / "state/win"
        directory.mkdir(parents=True)
        with (directory / "launch.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Another win launch", result.stderr)
        self.assertFalse((self.root / "virsh_calls").exists())


if __name__ == "__main__":
    unittest.main()
