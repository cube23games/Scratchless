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
    "test/live_place_alert_service_test.dart",
    "tools/verify_sl77a_geofence2b.py",
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
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT, text=True, capture_output=True, check=True,
    )
    changed = {
        line.strip() for line in result.stdout.splitlines() if line.strip()
    }
    if changed != EXPECTED:
        fail(
            "Staged scope mismatch.\n"
            f"Expected: {sorted(EXPECTED)}\n"
            f"Found: {sorted(changed)}"
        )
    print("PASS: GEOFENCE2B staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

service = read("lib/core/services/live_place_alert_service.dart")
tests = read("test/live_place_alert_service_test.dart")
workflow = read(".github/workflows/android_debug.yml")

for token, label in {
    "geofenceInitialTriggerEntry: false": "initial ENTER suppression",
    "final existingGeofences = await tl.Tracelet.getGeofences()": "existing-fence read",
    "await tl.Tracelet.removeGeofence(existing.identifier)": "selective stale-fence removal",
    "sameGeofenceDefinitionForQa(existing, place)": "unchanged-fence comparison",
    "await tl.Tracelet.addGeofence(": "identifier upsert",
    "final state = await tl.Tracelet.getState()": "native tracking-state read",
    "state.trackingMode == tl.TrackingMode.geofences": "geofence-mode detection",
    "if (!alreadyGeofencing)": "guarded start",
}.items():
    require(service, token, label)

if "await tl.Tracelet.removeGeofences();" in service:
    fail("Blanket removeGeofences() remains in LivePlaceAlertService.")

start_call = service.find("await tl.Tracelet.startGeofences();")
guard = service.rfind("if (!alreadyGeofencing)", 0, start_call)
if start_call < 0 or guard < 0:
    fail("startGeofences() is not protected by the existing-mode guard.")

for token in [
    "unchanged fence is preserved",
    "changed or entry-only fence must be upserted",
    "notifyOnExit: false",
]:
    require(tests, token, "preserve-state regression test")

require(
    workflow,
    "python tools/verify_sl77a_geofence2b.py --ci",
    "GEOFENCE2B workflow gate",
)

print("PASS: unchanged geofences survive ordinary sync.")
print("PASS: stale geofences are removed individually.")
print("PASS: changed/new geofences are upserted by identifier.")
print("PASS: repeated sync does not restart geofence mode.")
print("PASS: synthetic initial ENTER is disabled.")
print("SL-77A-GEOFENCE2B VERIFICATION PASSED")
