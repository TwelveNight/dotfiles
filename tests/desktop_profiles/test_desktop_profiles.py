import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "dot_local/lib/desktop-profiles"))
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from desktop_profiles import Profiles


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.root = self.home / '.config/desktop-profiles'
        self.root.mkdir(parents=True)
        self.registry = {
            'inir': {'compositor': 'niri', 'links': ['niri'], 'start': ['/bin/true']},
            'nyxuri': {'compositor': 'niri', 'links': ['niri', 'noctalia', 'kitty-nyxuri'], 'start': ['/bin/true']},
            'hyprland-ii': {'compositor': 'hypr', 'links': ['hypr'], 'start': ['/bin/true']},
        }
        (self.root / 'profiles.json').write_text(json.dumps(self.registry))
        for name, data in self.registry.items():
            for app in data['links']:
                target = self.root / name / app
                target.mkdir(parents=True)
                (target / ('hyprland.lua' if app == 'hypr' else 'config.kdl')).write_text(name)
        for app, owner in [('niri', 'inir'), ('noctalia', 'nyxuri'), ('kitty-nyxuri', 'nyxuri'), ('hypr', 'hyprland-ii')]:
            (self.home / '.config' / app).symlink_to(self.root / owner / app)
        self.profiles = Profiles(self.home)

    def test_switch_retains_other_compositor_and_custom_files(self):
        personal = self.root / 'inir/niri/__custom__.kdl'
        personal.write_text('user settings')
        previous = self.profiles.select('nyxuri')
        self.assertEqual((self.home / '.config/niri/config.kdl').read_text(), 'nyxuri')
        self.assertEqual((self.home / '.config/hypr/hyprland.lua').read_text(), 'hyprland-ii')
        self.profiles.restore(previous)
        self.assertEqual(personal.read_text(), 'user settings')
        self.profiles.guard('inir')

    def test_install_guard_rejects_wrong_desktop(self):
        self.profiles.select('nyxuri')
        with self.assertRaisesRegex(ValueError, 'maintain inir'):
            self.profiles.guard('inir')

    def test_directory_and_repository_links_are_not_overwritten(self):
        target = self.home / '.config/niri'
        target.unlink()
        target.mkdir()
        (target / 'keep').write_text('untouched')
        with self.assertRaisesRegex(ValueError, 'not been migrated'):
            self.profiles.select('nyxuri')
        self.assertEqual((target / 'keep').read_text(), 'untouched')
        target.rename(target.with_name('old-niri'))
        target.symlink_to(self.home / 'repo')
        with self.assertRaisesRegex(ValueError, 'not managed'):
            self.profiles.select('nyxuri')

    def test_failed_switch_rolls_back_every_link(self):
        replace = self.profiles.replace_link
        calls = 0
        def fail_once(path, target):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError('injected link failure')
            replace(path, target)
        # Force a second link to change so partial failure exercises rollback.
        (self.home / '.config/noctalia').unlink()
        (self.home / '.config/noctalia').symlink_to(self.root / 'inir/niri')
        with patch.object(self.profiles, 'replace_link', side_effect=fail_once):
            with self.assertRaises(OSError):
                self.profiles.select('nyxuri')
        self.profiles.guard('inir')
        self.assertEqual((self.home / '.config/noctalia').resolve(), self.root / 'inir/niri')

    def test_maintenance_targets_owner_and_restores_even_on_failure(self):
        self.profiles.select('nyxuri')
        command = [sys.executable, '-c', 'from pathlib import Path; import sys; Path(sys.argv[1]).write_text("updated inir"); sys.exit(7)', str(self.home / '.config/niri/result')]
        with patch.object(self.profiles, 'compositors', return_value=[]):
            self.assertEqual(self.profiles.maintain('inir', command), 7)
        self.assertEqual((self.root / 'inir/niri/result').read_text(), 'updated inir')
        self.assertFalse((self.root / 'nyxuri/niri/result').exists())
        self.profiles.guard('nyxuri')

    def test_other_running_niri_blocks_maintenance_switch(self):
        self.profiles.select('nyxuri')
        with patch.object(self.profiles, 'compositors', return_value=[(10, 'niri')]):
            with self.assertRaisesRegex(ValueError, 'log out'):
                self.profiles.maintain('inir', ['/bin/true'])
        self.profiles.guard('nyxuri')

    def test_existing_graphical_session_blocks_login(self):
        with patch.object(self.profiles, 'compositors', return_value=[(10, 'Hyprland')]), patch('subprocess.Popen') as start:
            with self.assertRaisesRegex(ValueError, 'still running'):
                self.profiles.run('nyxuri')
            start.assert_not_called()
        self.profiles.guard('inir')

    def test_failed_login_restores_previous_profile(self):
        with patch.object(self.profiles, 'compositors', return_value=[]):
            self.assertEqual(self.profiles.run('nyxuri', ['/bin/false']), 1)
        self.profiles.guard('inir')

    def test_missing_executable_restores_previous_profile(self):
        with patch.object(self.profiles, 'compositors', return_value=[]):
            with self.assertRaises(FileNotFoundError):
                self.profiles.run('nyxuri', ['/does-not-exist'])
        self.profiles.guard('inir')

    def test_lock_prevents_overlapping_login_and_updates(self):
        with self.profiles.lock('transition'):
            with self.assertRaisesRegex(ValueError, 'in progress'):
                with self.profiles.lock('transition', blocking=False):
                    self.fail('concurrent transition acquired lock')


if __name__ == '__main__':
    unittest.main()
