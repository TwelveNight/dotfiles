import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "dot_local/lib/desktop-profiles"))
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import migrate


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.config = self.home / '.config'
        for name in ('hypr', 'niri', 'nyxuri-desktop/niri', 'nyxuri-desktop/noctalia', 'nyxuri-desktop/kitty-nyxuri', 'kitty-nyxuri', 'systemd/user'):
            (self.config / name).mkdir(parents=True, exist_ok=True)
        (self.config / 'hypr/hyprland.lua').write_text('original hypr')
        (self.config / 'niri/config.kdl').write_text('original inir')
        (self.config / 'nyxuri-desktop/niri/config.kdl').write_text('"~/.config/nyxuri-desktop/niri/scripts/test.py"')
        (self.config / 'nyxuri-desktop/niri/effects.kdl').symlink_to('config.kdl')
        self.absolute_target = self.config / 'nyxuri-desktop/niri/config.kdl'
        (self.config / 'nyxuri-desktop/niri/absolute-effects.kdl').symlink_to(self.absolute_target)
        (self.config / 'nyxuri-desktop/noctalia/example__custom__.toml').write_text('custom = "~/.config/nyxuri-desktop/noctalia/tool.py"\n')
        (self.config / 'kitty-nyxuri/kitty.conf').write_text('legacy kitty')
        for name in ('nyxuri-niri.service', 'nyxuri-shell.service', 'nyxuri-clipboard.service'):
            (self.config / 'systemd/user' / name).write_text('ExecStart=%h/.config/nyxuri-desktop/niri/tool.py')
        (self.home / '.local/bin').mkdir(parents=True)
        (self.home / '.local/bin/nyxuri').symlink_to('/old/source/install.sh')
        self.settings = self.home / '.local/state/nyxuri-desktop/noctalia/noctalia/settings.toml'
        self.settings.parent.mkdir(parents=True)
        self.original_settings = ('volume = 37\n[[plugins.source]]\n'
                                  'location = "~/.config/nyxuri-desktop/noctalia/plugins"\n')
        self.settings.write_text(self.original_settings)
        self.package = Path(migrate.__file__).parent

    def test_preserves_directory_identity_and_user_customizations(self):
        inode = (self.config / 'hypr').stat().st_ino
        backup = migrate.apply(self.home, self.package)
        self.assertEqual((self.config / 'hypr').stat().st_ino, inode)
        self.assertEqual((self.config / 'hypr/hyprland.lua').read_text(), 'original hypr')
        self.assertEqual((self.config / 'niri/config.kdl').read_text(), 'original inir')
        root = self.config / 'desktop-profiles/nyxuri'
        self.assertIn('~/.config/noctalia/', (root / 'noctalia/example__custom__.toml').read_text())
        self.assertEqual((root / 'niri/effects.kdl').readlink(), Path('config.kdl'))
        self.assertEqual((root / 'niri/absolute-effects.kdl').readlink(), Path('config.kdl'))
        self.assertTrue((root / 'niri/absolute-effects.kdl').is_file())
        self.assertEqual((backup / 'legacy-kitty-nyxuri/kitty.conf').read_text(), 'legacy kitty')
        self.assertFalse((self.config / 'nyxuri-desktop').exists())
        self.assertEqual(self.settings.read_text(), self.original_settings.replace('.config/nyxuri-desktop/', '.config/'))
        migrate.rollback(self.home, backup)
        self.assertEqual(self.settings.read_text(), self.original_settings)
        self.assertFalse((self.config / 'hypr').is_symlink())
        self.assertEqual((self.config / 'hypr').stat().st_ino, inode)
        self.assertIn('~/.config/nyxuri-desktop/', (self.config / 'nyxuri-desktop/niri/config.kdl').read_text())
        self.assertEqual((self.config / 'nyxuri-desktop/niri/absolute-effects.kdl').readlink(), self.absolute_target)
        self.assertEqual((self.config / 'kitty-nyxuri/kitty.conf').read_text(), 'legacy kitty')
        self.assertEqual((self.home / '.local/bin/nyxuri').readlink(), Path('/old/source/install.sh'))

    def test_failed_validation_rolls_back_directories_and_links(self):
        with patch.object(migrate.Profiles, 'guard', side_effect=ValueError('test failure')):
            with self.assertRaisesRegex(ValueError, 'test failure'):
                migrate.apply(self.home, self.package)
        self.assertEqual(self.settings.read_text(), self.original_settings)
        self.assertFalse((self.config / 'hypr').is_symlink())
        self.assertTrue((self.config / 'nyxuri-desktop/niri/effects.kdl').is_symlink())
        self.assertEqual((self.config / 'kitty-nyxuri/kitty.conf').read_text(), 'legacy kitty')


if __name__ == '__main__':
    unittest.main()
