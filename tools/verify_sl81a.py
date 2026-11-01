#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/models/starting_plan.dart': [
        'class StartingPlan',
        'preferredUrgeScriptId',
        'prefersPrivateSupport',
    ],
    'lib/core/storage/app_storage.dart': [
        "_startingPlanKey = 'starting_plan_v1'",
        'StartingPlan.fromLegacy',
        'jsonEncode(state.startingPlan.toJson())',
    ],
    'lib/features/onboarding/onboarding_screen.dart': [
        'final StartingPlan startingPlan;',
        'problemFit: _problemFit',
        'triggers: _triggerSelections.toList()',
        'preferredRescue: _rescuePlan',
        'supportPreference: _privacyPreference',
    ],
    'lib/features/profile/profile_screen.dart': [
        'StartingPlanEditorScreen(plan: startingPlan)',
        "'Starting Plan'",
        'onUpdateStartingPlan(result)',
    ],
    'lib/features/urge/urge_mode_screen.dart': [
        'widget.startingPlan.preferredUrgeScriptId',
        "'Your Starting Plan'",
        'widget.startingPlan.prefersPrivateSupport',
    ],
    'lib/app/scratchless_app.dart': [
        'StartingPlan _startingPlan = StartingPlan.defaults()',
        'startingPlan: _startingPlan',
        'onUpdateStartingPlan: _updateStartingPlan',
    ],
}

failed = False
for rel, needles in checks.items():
    text = (ROOT / rel).read_text()
    for needle in needles:
        if needle not in text:
            print(f'FAIL: {rel} missing {needle!r}')
            failed = True

profile = (ROOT / 'lib/features/profile/profile_screen.dart').read_text()
if 'class _EditGoalScreen' in profile:
    print('FAIL: old one-off goal editor still present')
    failed = True

if failed:
    sys.exit(1)

print('PASS: SL-81A Starting Plan source contract verified.')
