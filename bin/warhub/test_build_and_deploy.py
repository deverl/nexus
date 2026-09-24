#!/usr/bin/env python3
"""Tests for JSON-defined {{PLACEHOLDER}} variables and notify_if_skipped."""

import importlib.util
import io
import sys
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

_SCRIPT = Path('./build-box/usr/local/bin/build_and_deploy.py')
_spec = importlib.util.spec_from_file_location('build_and_deploy', _SCRIPT)
assert _spec is not None and _spec.loader is not None
bad = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bad)


def _collect(steps, current_index, step_status=None, already_notified=None, defs=None):
    return bad.collect_notify_if_skipped(
        steps,
        current_index,
        step_status if step_status is not None else {},
        already_notified if already_notified is not None else set(),
        defs if defs is not None else {},
    )


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


class CollectNotifyIfSkippedTest(unittest.TestCase):
    def test_later_step_collects_earlier_unrun_marked_step(self):
        # Would fail if skipping A and running B did not yield a notification target.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C111'},
            {'text': 'B'},
        ]
        self.assertEqual(
            _collect(steps, 1),
            [(0, 'C111', 'A', 'B')],
        )

    def test_running_the_step_first_does_not_notify(self):
        # Would fail if an already-run earlier step were still collected.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C111'},
            {'text': 'B'},
        ]
        self.assertEqual(_collect(steps, 1, step_status={0: True}), [])

    def test_failed_attempt_counts_as_executed(self):
        # Would fail if a failed earlier step were treated as skipped.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C111'},
            {'text': 'B'},
        ]
        self.assertEqual(_collect(steps, 1, step_status={0: False}), [])

    def test_empty_and_missing_keys_are_noop(self):
        # Would fail if missing, empty, or whitespace-only keys produced targets.
        steps = [
            {'text': 'A'},
            {'text': 'B', 'notify_if_skipped': ''},
            {'text': 'C', 'notify_if_skipped': '   '},
            {'text': 'D'},
        ]
        self.assertEqual(_collect(steps, 3), [])

    def test_jumping_over_several_marked_steps_collects_each(self):
        # Would fail if only the immediately previous step were considered.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C1'},
            {'text': 'B', 'notify_if_skipped': 'C2'},
            {'text': 'C'},
        ]
        self.assertEqual(
            _collect(steps, 2),
            [(0, 'C1', 'A', 'C'), (1, 'C2', 'B', 'C')],
        )

    def test_already_notified_is_not_collected_again(self):
        # Would fail if a previously notified index were posted a second time.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C1'},
            {'text': 'B', 'notify_if_skipped': 'C2'},
            {'text': 'C'},
        ]
        self.assertEqual(
            _collect(steps, 2, already_notified={0}),
            [(1, 'C2', 'B', 'C')],
        )

    def test_channel_id_placeholders_are_interpolated(self):
        # Would fail if {{CHAN}} were left unsubstituted.
        steps = [
            {'text': 'A', 'notify_if_skipped': '{{CHAN}}'},
            {'text': 'B'},
        ]
        self.assertEqual(
            _collect(steps, 1, defs={'CHAN': 'C064603CX9T'}),
            [(0, 'C064603CX9T', 'A', 'B')],
        )

    def test_display_only_steps_are_not_collected(self):
        # Would fail if a no-text section line were treated as a skipped step.
        steps = [
            {'help': 'Section'},
            {'text': 'A', 'notify_if_skipped': 'C1'},
            {'text': 'B'},
        ]
        self.assertEqual(_collect(steps, 2), [(1, 'C1', 'A', 'B')])


class NotifySkippedStepsTest(unittest.TestCase):
    def test_posts_once_and_records_notified(self):
        # Would fail if Slack were not posted, or if a second call posted again.
        steps = [
            {'text': 'Check MRs', 'notify_if_skipped': 'C1'},
            {'text': 'git pull'},
        ]
        already_notified: set[int] = set()
        posted: list[tuple[str, str]] = []

        with patch('sys.stdout', new=io.StringIO()):
            bad.notify_skipped_steps(
                steps,
                1,
                {},
                already_notified,
                definitions={'USERNAME': 'dstokes'},
                post_message=lambda channel_id, text: posted.append((channel_id, text)),
            )
        self.assertEqual(
            posted,
            [('C1', 'dstokes skipped "Check MRs" and is running "git pull"')],
        )
        self.assertEqual(already_notified, {0})

        posted.clear()
        with patch('sys.stdout', new=io.StringIO()):
            bad.notify_skipped_steps(
                steps,
                1,
                {},
                already_notified,
                definitions={'USERNAME': 'dstokes'},
                post_message=lambda channel_id, text: posted.append((channel_id, text)),
            )
        self.assertEqual(posted, [])

    def test_post_failure_does_not_raise_and_does_not_retry(self):
        # Would fail if a Slack error aborted the caller or retried on the next call.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C1'},
            {'text': 'B'},
        ]
        already_notified: set[int] = set()
        calls = {'n': 0}

        def boom(channel_id: str, text: str) -> None:
            calls['n'] += 1
            raise RuntimeError('slack down')

        with patch('sys.stdout', new=io.StringIO()):
            bad.notify_skipped_steps(
                steps,
                1,
                {},
                already_notified,
                definitions={'USERNAME': 'dstokes'},
                post_message=boom,
            )
            bad.notify_skipped_steps(
                steps,
                1,
                {},
                already_notified,
                definitions={'USERNAME': 'dstokes'},
                post_message=boom,
            )
        self.assertEqual(calls['n'], 1)
        self.assertEqual(already_notified, {0})


class RunStepsNotifyHookTest(unittest.TestCase):
    def test_run_steps_notifies_before_executing_a_later_step(self):
        # Would fail if the menu run path never called notify_skipped_steps.
        steps = [
            {'text': 'A', 'notify_if_skipped': 'C1'},
            {'text': 'B', 'auto_advance': True},
            {'text': 'C'},
        ]
        calls: list[int] = []

        def fake_notify(steps_arg, current_index, step_status, already_notified, **kwargs):
            calls.append(current_index)

        with (
            patch.object(bad, 'notify_skipped_steps', fake_notify),
            patch.object(bad.Command, 'run', return_value=0),
            patch.object(bad.time, 'sleep'),
            patch('sys.stdout', new=io.StringIO()),
        ):
            bad.Menu._run_steps_until_menu_return(
                steps,
                1,
                deploy_type='full',
                build_name='vanguard',
                build_directory='/',
                step_status={},
                auto_advance_delay=0,
                already_notified=set(),
            )
        self.assertEqual(calls, [1])


def _prefix(step_index, step, step_status=None, already_notified=None, defs=None):
    return bad.Menu._step_status_prefix(
        step_index,
        step,
        step_status if step_status is not None else {},
        already_notified if already_notified is not None else set(),
        defs if defs is not None else {},
    )


class StepStatusPrefixTest(unittest.TestCase):
    def test_unrun_marked_step_shows_flag(self):
        # Would fail if a notify_if_skipped step used a blank prefix before it runs.
        step = {'text': 'A', 'notify_if_skipped': 'C1'}
        self.assertEqual(
            _prefix(0, step),
            f'{bad.Style.YELLOW}⚑{bad.Style.RESET} ',
        )

    def test_skipped_marked_step_shows_warning(self):
        # Would fail if a notified skip still looked unrun or used the flag.
        step = {'text': 'A', 'notify_if_skipped': 'C1'}
        self.assertEqual(
            _prefix(0, step, already_notified={0}),
            f'{bad.Style.YELLOW}⚠{bad.Style.RESET} ',
        )

    def test_success_overrides_flag(self):
        # Would fail if a completed marked step kept the flag instead of a check.
        step = {'text': 'A', 'notify_if_skipped': 'C1'}
        self.assertEqual(
            _prefix(0, step, step_status={0: True}),
            f'{bad.Style.GREEN}✓{bad.Style.RESET} ',
        )

    def test_failure_overrides_flag(self):
        # Would fail if a failed marked step kept the flag instead of an x.
        step = {'text': 'A', 'notify_if_skipped': 'C1'}
        self.assertEqual(
            _prefix(0, step, step_status={0: False}),
            f'{bad.Style.RED}✗{bad.Style.RESET} ',
        )

    def test_empty_and_missing_keys_stay_blank(self):
        # Would fail if missing, empty, whitespace, or null keys showed a flag.
        self.assertEqual(_prefix(0, {'text': 'A'}), '  ')
        self.assertEqual(_prefix(0, {'text': 'A', 'notify_if_skipped': ''}), '  ')
        self.assertEqual(_prefix(0, {'text': 'A', 'notify_if_skipped': '   '}), '  ')
        self.assertEqual(_prefix(0, {'text': 'A', 'notify_if_skipped': None}), '  ')

    def test_placeholder_channel_counts_as_marked(self):
        # Would fail if {{CHAN}} were treated as empty before interpolation.
        step = {'text': 'A', 'notify_if_skipped': '{{CHAN}}'}
        self.assertEqual(
            _prefix(0, step, defs={'CHAN': 'C064603CX9T'}),
            f'{bad.Style.YELLOW}⚑{bad.Style.RESET} ',
        )


if __name__ == '__main__':
    unittest.main()
