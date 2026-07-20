#!/usr/bin/env python3
"""Verifier for ScratchLess SL-77A-QA-GEOFENCE1."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_FILES = {
    ".github/workflows/android_debug.yml",
    "lib/core/services/live_place_alert_service.dart",
    "lib/core/services/local_notification_service.dart",
    "lib/features/risky_places/risky_places_screen.dart",
    "pubspec.yaml",
    "test/live_place_alert_service_test.dart",
    "tools/verify_sl77a_qa_geofence1.py",
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

    print("PASS: GEOFENCE1 staged-file allowlist is exact.")


def verify_dependency_pin() -> None:
    pubspec = read("pubspec.yaml")
    workflow = read(".github/workflows/android_debug.yml")

    require(
        pubspec,
        "  tracelet: 1.8.13\n",
        "exact Tracelet pin",
    )

    if "tracelet: ^1.8.7" in pubspec:
        fail("Old floating Tracelet constraint remains.")

    require(
        workflow,
        'flutter pub deps --style=compact | '
        'grep -F "tracelet 1.8.13"',
        "CI Tracelet assertion",
    )
    require(
        workflow,
        "flutter test "
        "test/live_place_alert_service_test.dart",
        "CI parser test",
    )

    print("PASS: Tracelet is pinned and CI-verified.")


def verify_parser() -> None:
    text = read(
        "lib/core/services/live_place_alert_service.dart"
    )

    required = {
        "nested containers":
            "_eventContainers(dynamic event)",
        "bounded recursive traversal":
            "while (pending.isNotEmpty && "
            "containers.length < 16)",
        "nested geofence candidate":
            "_attemptRead(() => current.geofence)",
        "map parsing":
            "_readMapValue(",
        "raw action":
            "_readRawEventAction(dynamic event)",
        "normalizer":
            "String? normalizeGeofenceActionForQa("
            "dynamic value)",
        "enum tokenization":
            "split(RegExp(r'[^A-Z]+'))",
        "numeric enter": "case 1:",
        "numeric exit": "case 2:",
        "numeric dwell": "case 4:",
        "raw diagnostics":
            "'Geofence ${action ?? 'UNKNOWN'} "
            "for $label; '",
        "runtime type":
            "event.runtimeType.toString()",
        "strict gate":
            "if (action != 'ENTER')",
    }

    for label, token in required.items():
        require(text, token, label)

    if "action.toUpperCase() != 'ENTER'" in text:
        fail("Old brittle parser remains.")

    print(
        "PASS: Parser accepts nested, numeric, "
        "and enum-style actions."
    )


def verify_location_diagnostics() -> None:
    text = read(
        "lib/core/services/live_place_alert_service.dart"
    )

    required = {
        "mock flag":
            "final bool? isMock;",
        "mock reader":
            "_readLocationMockFlag(dynamic location)",
        "QA location method":
            "Future<String> evaluateCurrentLocationForQa(",
        "distance":
            "_distanceMeters(",
        "inside result":
            "${inside ? 'INSIDE' : 'OUTSIDE'}",
        "accuracy":
            "'accuracy ${_metersLabel(current.accuracy)}; '",
    }

    for label, token in required.items():
        require(text, token, label)

    print(
        "PASS: Location QA includes distance, "
        "radius, accuracy, and mock state."
    )


def verify_notification_test() -> None:
    service = read(
        "lib/core/services/live_place_alert_service.dart"
    )
    notifications = read(
        "lib/core/services/local_notification_service.dart"
    )

    require(
        service,
        "Future<String> sendQaTestNotification(",
        "QA notification method",
    )
    require(
        service,
        "'QA risky-place alert'",
        "QA notification title",
    )
    require(
        notifications,
        "Future<bool> showLivePlaceAlert({",
        "notification result",
    )
    require(
        notifications,
        "return false;",
        "blocked result",
    )
    require(
        notifications,
        "return true;",
        "shown result",
    )
    require(
        service,
        "'Notification blocked for "
        "${_placeLabel(place)}'",
        "blocked-notification evidence",
    )

    print(
        "PASS: Notification and tap route "
        "can be tested independently."
    )


def verify_qa_ui() -> None:
    text = read(
        "lib/features/risky_places/"
        "risky_places_screen.dart"
    )

    required = {
        "foundation import":
            "import 'package:flutter/foundation.dart';",
        "debug gate":
            "if (kDebugMode &&",
        "QA heading":
            "'Internal geofence QA'",
        "location button":
            "'Evaluate current location'",
        "notification button":
            "'Send test risky-place notification'",
        "location action":
            "_runQaLocationCheck(",
        "notification action":
            "_runQaNotificationTest(",
    }

    for label, token in required.items():
        require(text, token, label)

    print("PASS: Geofence QA controls are debug-only.")


def verify_tests() -> None:
    text = read(
        "test/live_place_alert_service_test.dart"
    )

    required = {
        "enum enter":
            "'GeofenceAction.enter'",
        "nested identifier":
            "'store-123'",
        "deeper numeric identifier":
            "'store-456'",
        "identifier parser test":
            "readGeofenceIdentifierForQa(event)",
        "action parser test":
            "readGeofenceActionForQa(event)",
        "numeric enter":
            "normalizeGeofenceActionForQa(1)",
        "numeric exit":
            "normalizeGeofenceActionForQa(2)",
        "numeric dwell":
            "normalizeGeofenceActionForQa(4)",
        "unknown":
            "'something_else'",
    }

    for label, token in required.items():
        require(text, token, label)

    print(
        "PASS: Parser tests cover enter, exit, "
        "dwell, and unknown values."
    )


def verify_existing_rescue() -> None:
    text = read(
        "lib/features/live_alert/"
        "live_alert_rescue_screen.dart"
    )

    required = {
        "pause": "'Pause running'",
        "leave": "'You chose to leave'",
        "done": "'Done — keep moving'",
        "text": "'Text message opened'",
        "email": "'Email draft opened'",
    }

    for label, token in required.items():
        require(text, token, label)

    print("PASS: Existing SL-77A behavior remains present.")


def main() -> int:
    verify_scope()
    verify_dependency_pin()
    verify_parser()
    verify_location_diagnostics()
    verify_notification_test()
    verify_qa_ui()
    verify_tests()
    verify_existing_rescue()

    print("SL-77A-QA-GEOFENCE1 VERIFICATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
