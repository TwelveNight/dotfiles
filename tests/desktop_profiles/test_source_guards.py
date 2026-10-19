import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "dot_local/lib/desktop-profiles"))
import json
from pathlib import Path
import os
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from desktop_profiles import Profiles


class SourceGuardTests(unittest.TestCase):
    def test_original_maintenance_entries_stop_before_wrong_profile_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            root = home / '.config/desktop-profiles'
            root.mkdir(parents=True)
            registry = {
                'inir': {'compositor': 'niri', 'links': ['niri'], 'start': ['/bin/true']},
                'nyxuri': {'compositor': 'niri', 'links': ['niri'], 'start': ['/bin/true']},
                'hyprland-ii': {'compositor': 'hypr', 'links': ['hypr'], 'start': ['/bin/true']},
                'sekaipop': {'compositor': 'hypr', 'links': ['hypr'], 'start': ['/bin/true']},
            }
            (root / 'profiles.json').write_text(json.dumps(registry))
            for name, data in registry.items():
                target = root / name / data['compositor']
                target.mkdir(parents=True)
                (target / ('config.kdl' if data['compositor'] == 'niri' else 'hyprland.lua')).write_text(name)
            (home / '.config/niri').symlink_to(root / 'nyxuri/niri')
            (home / '.config/hypr').symlink_to(root / 'sekaipop/hypr')
            binary = home / '.local/bin/desktop-profile'
            binary.parent.mkdir(parents=True)
            module = Path(sys.modules["desktop_profiles"].__file__)
            binary.write_text('#!/usr/bin/python3\nimport sys\nsys.path.insert(0, ' + repr(str(module.parent)) + ')\nfrom desktop_profiles import main\nraise SystemExit(main())\n')
            binary.chmod(0o755)
            environment = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'))
            commands = [
                ['/home/night/Template/github/niri-dots/iNiR/setup', 'update', '--local'],
                ['/home/night/Template/github/niri-dots/iNiR/scripts/personal/install.sh', '-y'],
                ['/home/night/Template/github/hyprland-dots/ii-p3drovfx/setup', 'install-files'],
                ['/home/night/Template/github/hyprland-dots/ii-p3drovfx/setup-ii-p3drovfx.sh', '--yes'],
            ]
            for command in commands:
                with self.subTest(command=command):
                    result = subprocess.run(command, env=environment, cwd=home, capture_output=True, text=True, timeout=10)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('is not selected for', result.stderr)
            self.assertEqual((home / '.config/niri/config.kdl').read_text(), 'nyxuri')
            self.assertEqual((home / '.config/hypr/hyprland.lua').read_text(), 'sekaipop')


if __name__ == '__main__':
    unittest.main()
