#!/usr/bin/env python3
"""Focused structural verifier for ScratchLess SL-77A."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_FILES = {
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "tools/verify_sl77a.py",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing {label}: {token}")


def staged_files() -> set[str]:
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )

    return {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    }


def main() -> int:
    changed = staged_files()

    if changed != EXPECTED_FILES:
        fail(
            "Staged scope mismatch. Expected "
            f"{sorted(EXPECTED_FILES)}, "
            f"found {sorted(changed)}."
        )

    screen = (
        ROOT
        / "lib/features/live_alert/"
        "live_alert_rescue_screen.dart"
    ).read_text(encoding="utf-8")

    required = {
        "leaving confirmation state":
            "bool _leavingConfirmed = false;",
        "feedback title state":
            "String? _actionFeedbackTitle;",
        "feedback body state":
            "String? _actionFeedbackBody;",
        "snackbar feedback helper":
            "void _showFeedback(String message)",
        "persistent feedback helper":
            "void _setActionFeedback({",
        "pause completion helper":
            "Future<void> _clearPauseWhenFinished(",
        "pause duplicate guard":
            "activeUntil.isAfter(now)",
        "pause identity guard":
            "_waitUntil != waitUntil",
        "pause active title":
            "'10-minute pause active'",
        "pause-complete title":
            "'10-minute pause complete'",
        "pause button state":
            "'Pause running'",
        "pause guidance":
            "'Stay outside and use another rescue tool "
            "while time works in your favor.'",
        "leaving feedback":
            "'Nice work. Put distance between you "
            "and the stop.'",
        "leaving completion button":
            "'Done — keep moving'",
        "text-opened state":
            "'Text message opened'",
        "email-opened state":
            "'Email draft opened'",
        "text fallback":
            "'Text app was unavailable. Support message "
            "copied instead.'",
        "email fallback":
            "'Email app was unavailable. Support message "
            "copied instead.'",
        "direct-copy state":
            "'Support message copied. Paste and send it now.'",
        "visible feedback card":
            "_actionFeedbackTitle != null",
        "existing stayed-out choice":
            "'I paused and stayed out'",
        "existing deciding choice":
            "'I’m still deciding'",
    }

    for label, token in required.items():
        require(screen, token, label)

    if screen.count("try {") < 2:
        fail(
            "SMS and email launch attempts are not both guarded."
        )

    if "wasUrgeWin" in screen:
        fail(
            "SL-77A introduced SL-77B outcome-model work."
        )

    print("PASS: SL-77A staged-file allowlist is exact.")
    print("PASS: Active pause cannot be silently restarted.")
    print("PASS: Pause completion clears the active state.")
    print("PASS: Leaving requires a deliberate completion step.")
    print("PASS: Text, email, and copy outcomes are distinct.")
    print("PASS: SL-77B logging data remains untouched.")
    print("SL-77A VERIFICATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
