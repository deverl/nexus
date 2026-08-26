#!/usr/bin/env python3
"""Tests for JSON-defined {{PLACEHOLDER}} variables in build_and_deploy.py."""

import importlib.util
import io
import sys
import unittest
from contextlib import redirect_stderr
from pathlib import Path

_SCRIPT = Path('./build-box/usr/local/bin/build_and_deploy.py')
_spec = importlib.util.spec_from_file_location('build_and_deploy', _SCRIPT)
assert _spec is not None and _spec.loader is not None
bad = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bad)


class ApplyJsonVariableDefinitionsTest(unittest.TestCase):
    def test_json_definitions_are_substituted(self):
        # Would fail if JSON keys were not merged into the interpolation map.
        defs: bad.VariableDefinitions = {}
        bad.apply_json_variable_definitions({'SLACK_YADA_YADA': '92734923784'}, defs)
        self.assertEqual(
            bad.interpolate_variables('chan={{SLACK_YADA_YADA}}', defs),
            'chan=92734923784',
        )

    def test_missing_definitions_leave_map_unchanged(self):
        # Would fail if None were treated as an empty dict to iterate (or as an error).
        defs: bad.VariableDefinitions = {'KEEP': 'me'}
        bad.apply_json_variable_definitions(None, defs)
        self.assertEqual(defs, {'KEEP': 'me'})

    def test_json_overrides_existing_non_builtin(self):
        # Would fail if merge skipped keys that already exist.
        defs: bad.VariableDefinitions = {'SLACK_DEV_GENERAL': 'OLD'}
        bad.apply_json_variable_definitions({'SLACK_DEV_GENERAL': 'C064603CX9T'}, defs)
        self.assertEqual(defs['SLACK_DEV_GENERAL'], 'C064603CX9T')

    def test_builtin_names_cannot_be_overridden(self):
        # Would fail if PID (or other builtins) could be replaced from JSON.
        defs: bad.VariableDefinitions = {'PID': lambda: 'live'}
        with redirect_stderr(io.StringIO()) as err:
            with self.assertRaises(SystemExit) as ctx:
                bad.apply_json_variable_definitions({'PID': 'not-a-pid'}, defs)
        self.assertEqual(ctx.exception.code, 1)
        self.assertIn('PID', err.getvalue())
        self.assertEqual(defs['PID'](), 'live')

    def test_non_object_definitions_exit(self):
        # Would fail if a JSON array/string were silently ignored.
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as ctx:
                bad.apply_json_variable_definitions(['nope'], {})
        self.assertEqual(ctx.exception.code, 1)

    def test_non_string_value_exits(self):
        # Would fail if a JSON number were coerced or stored as-is.
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as ctx:
                bad.apply_json_variable_definitions({'SLACK_YADA_YADA': 92734923784}, {})
        self.assertEqual(ctx.exception.code, 1)

    def test_invalid_name_exits(self):
        # Would fail if names outside {{A-Za-z0-9_}} were accepted.
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as ctx:
                bad.apply_json_variable_definitions({'SLACK-YADA': 'x'}, {})
        self.assertEqual(ctx.exception.code, 1)

    def test_comment_keys_are_ignored(self):
        # Would fail if documentation keys were stored as interpolatable names.
        defs: bad.VariableDefinitions = {}
        bad.apply_json_variable_definitions(
            {
                'comment': 'ignored',
                'comment_slack_team__cs': 'This is a team (@cs)',
                'SLACK_TEAM__CS': 'S0B1S4ZN013',
            },
            defs,
        )
        self.assertEqual(defs, {'SLACK_TEAM__CS': 'S0B1S4ZN013'})
        self.assertEqual(
            bad.interpolate_variables('{{comment_slack_team__cs}}', defs),
            '{{comment_slack_team__cs}}',
        )

    def test_comment_keys_skip_value_validation(self):
        # Would fail if a comment_* value were type-checked like a real variable.
        defs: bad.VariableDefinitions = {}
        bad.apply_json_variable_definitions({'comment_note': 123, 'OK': 'yes'}, defs)
        self.assertEqual(defs, {'OK': 'yes'})


if __name__ == '__main__':
    unittest.main()
