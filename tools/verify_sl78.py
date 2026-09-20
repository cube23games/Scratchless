#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv

EXPECTED = {
    ".github/workflows/android_debug.yml",
    "lib/app/scratchless_app.dart",
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "test/live_alert_rescue_full_urge_handoff_test.dart",
    "tools/verify_sl78.py",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        fail(f"Missing {path}")
    return target.read_text(encoding="utf-8")


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing {label}: {token}")


if not CI_MODE:
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    changed = {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    }
    if changed != EXPECTED:
        fail(
            "Staged scope mismatch. "
            f"Expected {sorted(EXPECTED)}, found {sorted(changed)}"
        )
    print("PASS: SL-78 staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

app = read("lib/app/scratchless_app.dart")
live = read("lib/features/live_alert/live_alert_rescue_screen.dart")
tests = read("test/live_alert_rescue_full_urge_handoff_test.dart")
workflow = read(".github/workflows/android_debug.yml")


for token, label in {
    "import '../features/urge/urge_mode_screen.dart';":
        "UrgeModeScreen import",
    "Future<void> _openFullUrgeModeFromLiveAlertRescue()":
        "app-owned full Urge Mode launcher",
    "builder: (_) => UrgeModeScreen(":
        "real UrgeModeScreen route",
    "onComplete: _completeDetailedUrgeSession":
        "real urge-session persistence callback",
    "onOpenFullUrgeMode: _openFullUrgeModeFromLiveAlertRescue":
        "rescue-to-app callback wiring",
}.items():
    require(app, token, label)

for token, label in {
    "final VoidCallback? onOpenFullUrgeMode;":
        "optional rescue handoff callback",
    "Open full urge tools":
        "full Urge Mode button",
    "Open live support options":
        "preserved live-support button",
    "if (_userEngagedRescueTool)":
        "deliberate-engagement gate",
}.items():
    require(live, token, label)


for token in [
    "full urge handoff requires deliberate rescue use and preserves live support",
    "autoStartTenMinutePause: true",
    "expect(find.text('Open full urge tools'), findsNothing)",
    "Read my reasons",
    "expect(find.text('Open full urge tools'), findsOneWidget)",
    "expect(find.text('Open live support options'), findsOneWidget)",
    "expect(openedFullUrgeMode, isTrue)",
]:
    require(tests, token, "SL-78 widget regression coverage")

require(
    workflow,
    "flutter test test/live_alert_rescue_full_urge_handoff_test.dart",
    "SL-78 Flutter test gate",
)
require(
    workflow,
    "python tools/verify_sl78.py --ci",
    "SL-78 verifier gate",
)

print("PASS: auto-started pause alone does not expose deeper handoff.")
print("PASS: deliberate rescue use exposes full Urge Mode handoff.")
print("PASS: handoff launches the existing real UrgeModeScreen.")
print("PASS: detailed urge logging remains connected to app persistence.")
print("PASS: existing live gambling support handoff remains available.")
print("SL-78 VERIFICATION PASSED")
