#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ALLOWED = {
    ".github/workflows/android_debug.yml",
    "docs/google_play/sl81c_background_location_submission.md",
    "lib/core/services/location_permission_plan_service.dart",
    "lib/features/privacy/privacy_screen.dart",
    "lib/features/risky_places/risky_places_screen.dart",
    "test/sl81c_location_privacy_test.dart",
    "tools/verify_sl81c.py",
}


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"{label}: missing {token!r}")


def staged_files() -> set[str]:
    output = subprocess.check_output(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
    )
    return {line.strip() for line in output.splitlines() if line.strip()}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()

    if not args.ci:
        actual = staged_files()
        if actual != ALLOWED:
            fail(
                "staged-file scope mismatch. "
                f"expected={sorted(ALLOWED)} actual={sorted(actual)}"
            )
        print("PASS: SL-81C staged-file scope is exact.")
    else:
        print("PASS: CI mode skips staged-file scope.")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text()
    plan = (ROOT / "lib/core/services/location_permission_plan_service.dart").read_text()
    risky = (ROOT / "lib/features/risky_places/risky_places_screen.dart").read_text()
    privacy = (ROOT / "lib/features/privacy/privacy_screen.dart").read_text()
    docs = (ROOT / "docs/google_play/sl81c_background_location_submission.md").read_text()
    workflow = (ROOT / ".github/workflows/android_debug.yml").read_text()

    require(
        manifest,
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        "Android manifest",
    )

    for token in (
        "backgroundDisclosureTitle",
        "backgroundDisclosureBody",
        "location data",
        "even when the app is closed or not in use",
        "Live Risky Place alerts",
        "does not use location for advertising",
        "locationPrivacySummary",
    ):
        require(plan, token, "Location disclosure contract")

    for token in (
        "_showBackgroundLocationDisclosure",
        "Not now",
        "Continue",
        "await widget.onEnableLivePlaceAlertsBackground();",
        "_debugState.accessLevel != 'foregroundOnly'",
        "Location was not granted. Live Risky Place alerts remain off.",
        "Review privacy policy",
        "ScratchLessPrivacyScreen",
    ):
        require(risky, token, "Risky Places disclosure flow")

    method_start = risky.find("Future<void> _openAndroidLocationSettings()")
    if method_start < 0:
        fail("background setup method not found")
    method_end = risky.find("Future<void> _checkPermissionAgain()", method_start)
    if method_end < 0:
        fail("background setup method boundary not found")
    method = risky[method_start:method_end]

    disclosure_pos = method.find("_showBackgroundLocationDisclosure")
    callback_pos = method.find("onEnableLivePlaceAlertsBackground")
    settings_pos = method.find("LivePlaceAlertService.instance.openAppSettings")
    if not (0 <= disclosure_pos < callback_pos < settings_pos):
        fail(
            "expected disclosure -> foreground permission callback -> settings order"
        )

    if risky.count("LivePlaceAlertService.instance.openAppSettings()") != 1:
        fail(
            "all Risky Places settings entry points must route through the "
            "single disclosed background setup method"
        )

    for token in (
        "ScratchLess privacy policy",
        "Live Risky Places",
        "Background location is optional",
        "does not use location for advertising",
        "Android settings",
    ):
        require(privacy, token, "In-app privacy policy")

    for token in (
        "Declared background-location feature",
        "Live Risky Places",
        "Prominent in-app disclosure",
        "Permissions Declaration",
        "Reviewer video",
        "30 seconds",
        "Store listing copy",
        "Website privacy-policy section",
        "Data Safety",
        "third-party location/geofence SDK behavior",
    ):
        require(docs, token, "Play approval package")

    for token in (
        "flutter test test/sl81c_location_privacy_test.dart",
        "python tools/verify_sl81c.py --ci",
        "Test SL-81C background location privacy",
        "Verify SL-81C background location contract",
    ):
        require(workflow, token, "CI contract")

    print("SL-81C VERIFICATION PASSED")


if __name__ == "__main__":
    main()
