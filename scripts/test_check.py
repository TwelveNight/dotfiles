"""Regression tests for parsing and temporary-restore path confinement."""
import json
from pathlib import Path
import tempfile
import unittest

from check import confined, jsonc


class CheckTests(unittest.TestCase):
    def test_comments_and_trailing_commas_preserve_strings(self):
        self.assertEqual(jsonc('''{
          // A comment
          "url": "https://example.test/a//b", /* another comment */
          "text": "comma,} and quote \\\"", "list": [1, 2,],
        }'''), {'url': 'https://example.test/a//b', 'text': 'comma,} and quote "', 'list': [1, 2]})

    def test_invalid_json_is_rejected(self):
        with self.assertRaises(json.JSONDecodeError):
            jsonc('{"setting": true, , "other": false}')

    def test_unterminated_string_cannot_become_a_number(self):
        with self.assertRaises(json.JSONDecodeError):
            jsonc('{"setting": "1}')

    def test_parent_traversal_and_absolute_paths_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ['../escape', '/tmp/escape', '.config/../../escape']:
                with self.assertRaises(ValueError):
                    confined(root, name)

    def test_symlink_parent_escape_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / 'home'
            root.mkdir()
            (root / 'outside').symlink_to(Path(temporary), target_is_directory=True)
            with self.assertRaises(ValueError):
                confined(root, 'outside/escape')

    def test_normal_dotfile_path_is_allowed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.assertEqual(confined(root, '.config/zsh/.zshrc'), root / '.config/zsh/.zshrc')


if __name__ == '__main__':
    unittest.main()
