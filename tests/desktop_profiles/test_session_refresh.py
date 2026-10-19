import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "dot_local/lib/desktop-profiles"))
from pathlib import Path
import tempfile
import unittest

import refresh_sessions


class SessionRefreshTests(unittest.TestCase):
    def test_package_upgrade_preserves_metadata_and_restores_only_exec(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            session = root / 'niri.desktop'
            original = '[Desktop Entry]\nName=Niri new package\nExec=niri-session\nDesktopNames=niri\nX-Test=retained\n'
            session.write_text(original)
            refresh_sessions.refresh(root)
            expected = original.replace('Exec=niri-session', 'Exec=/home/night/.local/bin/desktop-profile run inir')
            self.assertEqual(session.read_text(), expected)
            inode = session.stat().st_ino
            refresh_sessions.refresh(root)
            self.assertEqual(session.stat().st_ino, inode)
            self.assertFalse((root / 'hyprland.desktop').exists())

    def test_redirected_package_entry_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            other = root / 'other'
            other.write_text('keep')
            (root / 'niri.desktop').symlink_to(other)
            with self.assertRaises(ValueError):
                refresh_sessions.refresh(root)
            self.assertEqual(other.read_text(), 'keep')


if __name__ == '__main__':
    unittest.main()
