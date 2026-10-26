"""Login preparation must fence delayed compositor watchers before publication."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

PACKAGE = Path(__file__).resolve().parents[2] / 'dot_local/lib/desktop-profiles'
sys.path.insert(0, str(PACKAGE))
import desktop_profiles as profiles
import session_runtime as session


class HandoffTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.runtime = Path(temporary.name)
        self.directory = self.runtime / 'desktop-profiles/session'
        self.directory.mkdir(parents=True)
        self.state = self.directory / 'desktop-session.json'
        self.identity = dict(desktop='niri', pid=99999999, key='NIRI_SOCKET',
                             value='/old/niri.sock', wayland='wayland-old')
        self.state.write_text(json.dumps(self.identity))
        self.env = dict(os.environ, XDG_RUNTIME_DIR=str(self.runtime))
        self.manager = dict(__NV_PRIME_RENDER_OFFLOAD='1', XMODIFIERS='@im=fcitx')
        self.calls = []

    def invoke(self, *args, **kwargs):
        if len(args) == 1 and isinstance(args[0], list):
            args = tuple(args[0])
        self.calls.append(args)
        output = json.dumps(self.manager) if 'show-environment' in args else ''
        if args[:3] == ('systemctl', '--user', 'set-environment'):
            self.assertFalse(self.state.exists(), 'publication preceded watcher invalidation')
            with (self.directory / 'desktop-session.lock').open('a') as contender:
                with self.assertRaises(BlockingIOError):
                    fcntl.flock(contender, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.manager.update(arg.split('=', 1) for arg in args[3:])
        elif args[:3] == ('systemctl', '--user', 'unset-environment'):
            for key in args[3:]:
                self.manager.pop(key, None)
        elif args[0] == 'dbus-update-activation-environment':
            self.manager.update(arg.split('=', 1) for arg in args[1:])
        return subprocess.CompletedProcess(args, 0, output, '')

    def watch_old(self):
        argv = ['session_runtime.py', 'watch', 'niri', '--identity', json.dumps(self.identity)]
        with patch.dict(os.environ, self.env, clear=True), patch('sys.argv', argv), patch.object(session, 'run', self.invoke):
            session.main()

    def test_manager_preparation_fences_old_watcher_before_new_socket_exists(self):
        with patch.dict(os.environ, self.env, clear=True), patch.object(profiles.subprocess, 'run', self.invoke):
            with profiles.wallpaper_session('dms-niri', 'native'):
                prepared = dict(self.manager)
                self.calls.clear()
                self.watch_old()
                self.assertEqual(self.manager, prepared, 'old watcher erased new login GPU/input environment')
                self.assertEqual(self.calls, [], 'old watcher stopped new login wallpaper')
        self.assertFalse(self.state.exists())

    def test_preparation_waits_for_existing_handoff_lock_before_invalidating_state(self):
        entered = threading.Event()
        errors = []
        def prepare():
            try:
                with session.prepare_session(self.env):
                    entered.set()
            except BaseException as error:
                errors.append(error)
        with (self.directory / 'desktop-session.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            thread = threading.Thread(target=prepare)
            thread.start()
            try:
                self.assertFalse(entered.wait(0.15), 'prepare bypassed existing watcher lock')
                self.assertTrue(self.state.exists())
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)
                thread.join(3)
        self.assertFalse(thread.is_alive())
        self.assertEqual(errors, [])
        self.assertTrue(entered.is_set())
        self.assertFalse(self.state.exists())

    def test_missing_runtime_fails_before_any_manager_operation(self):
        env = dict(self.env)
        env.pop('XDG_RUNTIME_DIR')
        with patch.dict(os.environ, env, clear=True), patch.object(profiles.subprocess, 'run', self.invoke):
            with self.assertRaises((ValueError, KeyError)):
                with profiles.wallpaper_session('dms-niri', 'native'):
                    self.fail('preparation accepted missing runtime directory')
        self.assertFalse(self.calls)


if __name__ == '__main__':
    unittest.main()
