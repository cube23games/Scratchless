#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv

EXPECTED = {
    ".github/workflows/android_debug.yml",
    "lib/core/services/live_place_alert_service.dart",
    "lib/core/services/place_alert_reentry_service.dart",
    "lib/features/risky_places/risky_places_screen.dart",
    "test/place_alert_reentry_service_test.dart",
    "tools/verify_sl77a_geofence2.py",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    p = ROOT / path
    if not p.is_file():
        fail(f"Missing {path}")
    return p.read_text(encoding="utf-8")


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing {label}: {token}")


if not CI_MODE:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    ).stdout

    changed = {
        line.strip()
        for line in out.splitlines()
        if line.strip()
    }

    if changed != EXPECTED:
        fail(
            f"Staged scope mismatch.\n"
            f"Expected: {sorted(EXPECTED)}\n"
            f"Found: {sorted(changed)}"
        )

    print("PASS: GEOFENCE2 staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

service = read(
    "lib/core/services/live_place_alert_service.dart"
)
reentry = read(
    "lib/core/services/place_alert_reentry_service.dart"
)
risky = read(
    "lib/features/risky_places/risky_places_screen.dart"
)
workflow = read(
    ".github/workflows/android_debug.yml"
)
tests = read(
    "test/place_alert_reentry_service_test.dart"
)

for token, label in {
    "notifyOnExit: true": "EXIT registration",
    "_minimumOutsideBeforeRearm": "stable outside window",
    "action == 'EXIT'": "EXIT handler",
    "markExited(": "EXIT persistence",
    "PlaceAlertReentryDecision.waitingForStableOutside":
        "jitter rejection",
    "PlaceAlertReentryDecision.rearmed":
        "confirmed re-arm",
    "bypassLongCooldown: confirmedReentry":
        "confirmed re-entry cooldown bypass",
    "'Re-armed ${_placeLabel(place)} after confirmed exit'":
        "re-arm diagnostic",
}.items():
    require(service, token, label)

if "notifyOnExit: false" in service:
    fail("Old entry-only geofence registration remains.")

for token, label in {
    "place_alert_last_exit_": "persistent exit timestamp",
    "minimumOutside": "minimum outside duration",
    "await clear(placeId)": "one-shot re-arm consumption",
}.items():
    require(reentry, token, label)

require(
    risky,
    "at least 90 seconds outside re-arms the place",
    "user-facing re-entry explanation",
)

require(
    workflow,
    "flutter test test/place_alert_reentry_service_test.dart",
    "re-entry CI test",
)

require(
    workflow,
    "python tools/verify_sl77a_geofence2.py --ci",
    "GEOFENCE2 CI verifier",
)

for token in [
    "quick return does not re-arm",
    "stable outside period re-arms once",
    "PlaceAlertReentryDecision.rearmed",
]:
    require(tests, token, "re-entry regression test")

print("SL-77A-GEOFENCE2 VERIFICATION PASSED")
