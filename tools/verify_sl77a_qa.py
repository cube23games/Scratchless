#!/usr/bin/env python3
"""Focused verifier for ScratchLess SL-77A-QA."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_FILES = {
    "lib/app/scratchless_app.dart",
    "lib/features/home/home_shell.dart",
    "lib/features/profile/profile_screen.dart",
    "tools/verify_sl77a_qa.py",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(relative_path: str) -> str:
    path = ROOT / relative_path

    if not path.is_file():
        fail(f"Missing file: {relative_path}")

    return path.read_text(encoding="utf-8")


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


def verify_scope() -> None:
    changed = staged_files()

    if changed != EXPECTED_FILES:
        fail(
            "Staged scope mismatch. Expected "
            f"{sorted(EXPECTED_FILES)}, "
            f"found {sorted(changed)}."
        )

    print("PASS: SL-77A-QA staged-file allowlist is exact.")


def verify_app() -> None:
    text = read("lib/app/scratchless_app.dart")

    required = {
        "test launcher":
            "Future<void> _openLiveAlertRescueTest() async",
        "safe fallback":
            "const fallbackLabel = 'Test risky place';",
        "saved risky-place use":
            "for (final place in _riskyPlaces)",
        "first usable place":
            "if (placeLabel == fallbackLabel)",
        "top-risk preference":
            "if (place.isTopRisk)",
        "real launcher reuse":
            "await _openLiveAlertRescue(",
        "manual pause start":
            "autoStartTenMinutePause: false,",
        "HomeShell argument":
            "onOpenLiveAlertRescueTest:",
        "HomeShell callback value":
            "_openLiveAlertRescueTest,",
    }

    for label, token in required.items():
        require(text, token, label)

    print("PASS: QA entry reuses the real app rescue launcher.")


def verify_home() -> None:
    text = read("lib/features/home/home_shell.dart")

    required = {
        "callback field":
            "final VoidCallback onOpenLiveAlertRescueTest;",
        "constructor argument":
            "required this.onOpenLiveAlertRescueTest,",
        "Profile argument":
            "onOpenLiveAlertRescueTest:",
        "Profile callback value":
            "widget.onOpenLiveAlertRescueTest,",
    }

    for label, token in required.items():
        require(text, token, label)

    if text.count("onOpenLiveAlertRescueTest") != 4:
        fail(
            "Expected four HomeShell QA callback references."
        )

    print("PASS: HomeShell bridges the QA callback.")


def verify_profile() -> None:
    text = read("lib/features/profile/profile_screen.dart")

    required = {
        "build-config import":
            "import '../../core/config/app_build_config.dart';",
        "callback field":
            "final VoidCallback onOpenLiveAlertRescueTest;",
        "constructor argument":
            "required this.onOpenLiveAlertRescueTest,",
        "QA-build gate":
            "if (AppBuildConfig.qaToolsEnabled) ...[",
        "internal label":
            "'Internal testing'",
        "test title":
            "'Test live alert rescue'",
        "real callback":
            "onTap: onOpenLiveAlertRescueTest",
        "QA-only explanation":
            "'ScratchLess QA only. Opens the real rescue screen "
            "with your saved reasons, accountability contact, "
            "and risky-place data.'",
    }

    for label, token in required.items():
        require(text, token, label)

    risky_index = text.find("'Risky places watchlist'")
    test_index = text.find("'Internal testing'")
    goals_index = text.find("'Goals & spend caps'")

    if min(risky_index, test_index, goals_index) < 0:
        fail("Could not find the expected Profile cards.")

    if not risky_index < test_index < goals_index:
        fail(
            "Internal testing card is not between "
            "Risky Places and Goals."
        )

    if text.count("onOpenLiveAlertRescueTest") != 3:
        fail(
            "Expected three Profile QA callback references."
        )

    print("PASS: Profile QA card is QA-build-only and correctly placed.")


def verify_sl77a() -> None:
    text = read(
        "lib/features/live_alert/live_alert_rescue_screen.dart"
    )

    required = {
        "pause state": "'Pause running'",
        "pause completion": "'10-minute pause complete'",
        "leaving state": "'You chose to leave'",
        "leaving completion": "'Done — keep moving'",
        "text feedback": "'Text message opened'",
        "email feedback": "'Email draft opened'",
    }

    for label, token in required.items():
        require(text, token, label)

    print("PASS: Existing SL-77A behavior remains present.")


def main() -> int:
    verify_scope()
    verify_app()
    verify_home()
    verify_profile()
    verify_sl77a()

    print("SL-77A-QA VERIFICATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
