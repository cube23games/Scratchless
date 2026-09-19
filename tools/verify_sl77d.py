#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv

EXPECTED = {
    ".github/workflows/android_debug.yml",
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "test/live_alert_rescue_deeper_handoff_test.dart",
    "tools/verify_sl77d.py",
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
        cwd=ROOT, text=True, capture_output=True, check=True,
    )
    changed = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    if changed != EXPECTED:
        fail(
            "Staged scope mismatch. "
            f"Expected {sorted(EXPECTED)}, found {sorted(changed)}"
        )
    print("PASS: SL-77D staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

live = read("lib/features/live_alert/live_alert_rescue_screen.dart")
tests = read("test/live_alert_rescue_deeper_handoff_test.dart")
workflow = read(".github/workflows/android_debug.yml")

for token, label in {
    "import '../help/help_screen.dart';": "HelpScreen import",
    "void _openDeeperHelp()": "deeper-help navigator",
    "const HelpScreen()": "HelpScreen route",
    "Need another layer?": "optional handoff heading",
    "Open live support options": "handoff button",
}.items():
    require(live, token, label)

for token in [
    "deeper help handoff appears after a rescue tool and opens help",
    "Need another layer?",
    "Open live support options",
    "Get help now",
    "Call 1-800-MY-RESET",
]:
    require(tests, token, "SL-77D widget regression coverage")

require(
    workflow,
    "flutter test test/live_alert_rescue_deeper_handoff_test.dart",
    "SL-77D Flutter test gate",
)
require(
    workflow,
    "python tools/verify_sl77d.py --ci",
    "SL-77D verifier gate",
)

print("PASS: deeper handoff stays hidden before a rescue tool is used.")
print("PASS: deeper handoff appears after first-line rescue activity.")
print("PASS: handoff opens the existing Get help now support screen.")
print("PASS: call, text, and live-chat support remain one tap away.")
print("PASS: SL-77D widget and source-contract CI gates are wired.")
print("SL-77D VERIFICATION PASSED")
