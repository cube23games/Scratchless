#!/usr/bin/env python3
"""Verifier for ScratchLess SL-77A-QA2."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv

EXPECTED_FILES = {
    ".github/workflows/android_debug.yml",
    "android/app/build.gradle.kts",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/src/qa/res/drawable/ic_launcher_qa.xml",
    "android/app/src/qa/res/drawable/qa_badge.xml",
    "lib/core/config/app_build_config.dart",
    "lib/core/services/live_place_alert_service.dart",
    "lib/core/services/place_alert_cooldown_service.dart",
    "lib/features/profile/profile_screen.dart",
    "lib/features/risky_places/risky_places_screen.dart",
    "test/app_build_config_test.dart",
    "tools/verify_sl77a_qa.py",
    "tools/verify_sl77a_qa2.py",
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
    if CI_MODE:
        print("PASS: CI mode skips staged-file scope.")
        return

    changed = staged_files()

    if changed != EXPECTED_FILES:
        fail(
            "Staged scope mismatch. Expected "
            f"{sorted(EXPECTED_FILES)}, "
            f"found {sorted(changed)}."
        )

    print("PASS: QA2 staged-file allowlist is exact.")


def verify_android_flavors() -> None:
    gradle = read("android/app/build.gradle.kts")
    manifest = read(
        "android/app/src/main/AndroidManifest.xml"
    )

    required_gradle = {
        "base application ID":
            'applicationId = "com.cube23.scratchless"',
        "flavor dimension":
            'flavorDimensions += "distribution"',
        "QA flavor":
            'create("qa")',
        "QA suffix":
            'applicationIdSuffix = ".qa"',
        "QA version suffix":
            'versionNameSuffix = "-qa"',
        "QA label":
            'resValue("string", "app_name", '
            '"ScratchLess QA")',
        "QA icon":
            '"@drawable/ic_launcher_qa"',
        "Store flavor":
            'create("store")',
        "Store label":
            'resValue("string", "app_name", '
            '"ScratchLess")',
        "Store icon":
            '"@mipmap/ic_launcher"',
    }

    for label, token in required_gradle.items():
        require(gradle, token, label)

    required_manifest = {
        "resource label":
            'android:label="@string/app_name"',
        "flavor icon":
            'android:icon="${appIcon}"',
        "flavor round icon":
            'android:roundIcon="${appIcon}"',
    }

    for label, token in required_manifest.items():
        require(manifest, token, label)

    if 'android:label="scratchless"' in manifest:
        fail("Old lowercase hardcoded launcher label remains.")

    print(
        "PASS: Android flavors have distinct IDs, "
        "labels, and icon treatment."
    )


def verify_build_config() -> None:
    config = read("lib/core/config/app_build_config.dart")

    required = {
        "compile-time variable":
            "'SCRATCHLESS_BUILD'",
        "safe Store default":
            "defaultValue: 'store'",
        "QA gate":
            "qaToolsEnabled = buildName == 'qa'",
        "Store state":
            "storeBuild = !qaToolsEnabled",
    }

    for label, token in required.items():
        require(config, token, label)

    if "defaultValue: 'qa'" in config:
        fail("QA must never be the default build behavior.")

    print("PASS: Store is the safe compile-time default.")


def verify_qa_gates() -> None:
    profile = read(
        "lib/features/profile/profile_screen.dart"
    )
    risky = read(
        "lib/features/risky_places/"
        "risky_places_screen.dart"
    )

    required_profile = {
        "config import":
            "import '../../core/config/"
            "app_build_config.dart';",
        "QA gate":
            "if (AppBuildConfig.qaToolsEnabled) ...[",
        "internal card":
            "'Internal testing'",
        "rescue test":
            "'Test live alert rescue'",
        "QA explanation":
            "'ScratchLess QA only. Opens the real "
            "rescue screen",
    }

    for label, token in required_profile.items():
        require(profile, token, label)

    required_risky = {
        "config import":
            "import '../../core/config/"
            "app_build_config.dart';",
        "QA gate":
            "if (AppBuildConfig.qaToolsEnabled &&",
        "QA card":
            "'Internal geofence QA'",
        "location test":
            "'Evaluate current location'",
        "notification test":
            "'Send test risky-place notification'",
        "cooldown reset":
            "'Reset alert cooldown for this place'",
        "QA explanation":
            "'ScratchLess QA only. Confirm Android’s "
            "reported location",
    }

    for label, token in required_risky.items():
        require(risky, token, label)

    if "kDebugMode" in profile:
        fail("Profile still depends on kDebugMode.")

    if "kDebugMode" in risky:
        fail("Risky Places still depends on kDebugMode.")

    profile_gate = profile.find(
        "if (AppBuildConfig.qaToolsEnabled) ...["
    )
    profile_card = profile.find("'Internal testing'")
    profile_goals = profile.find("'Goals & spend caps'")

    if not 0 <= profile_gate < profile_card < profile_goals:
        fail("Profile QA card is not inside the QA gate.")

    risky_gate = risky.find(
        "if (AppBuildConfig.qaToolsEnabled &&"
    )
    risky_card = risky.find("'Internal geofence QA'")
    recent_activity = risky.find(
        "'Recent live alert activity'"
    )

    if not 0 <= risky_gate < risky_card < recent_activity:
        fail("Geofence QA card is not inside the QA gate.")

    print(
        "PASS: QA controls are compile-time gated "
        "and Store-safe."
    )


def verify_cooldown_reset() -> None:
    cooldown = read(
        "lib/core/services/"
        "place_alert_cooldown_service.dart"
    )
    service = read(
        "lib/core/services/live_place_alert_service.dart"
    )
    risky = read(
        "lib/features/risky_places/"
        "risky_places_screen.dart"
    )

    required = {
        "cooldown clear":
            "Future<void> clear(String placeId) async",
        "service reset":
            "Future<String> resetQaCooldown(",
        "persistent clear":
            "PlaceAlertCooldownService.instance.clear("
            "place.id)",
        "burst-state clear":
            "_recentEntryHits.remove(place.id)",
        "reset activity":
            "'QA cooldown reset for $label'",
        "screen action":
            "_runQaCooldownReset(",
        "reset button":
            "'Reset alert cooldown for this place'",
    }

    combined = cooldown + "\n" + service + "\n" + risky

    for label, token in required.items():
        require(combined, token, label)

    print(
        "PASS: QA can reset persistent and "
        "in-memory alert cooldown state."
    )


def verify_qa_icon() -> None:
    icon = read(
        "android/app/src/qa/res/drawable/"
        "ic_launcher_qa.xml"
    )
    badge = read(
        "android/app/src/qa/res/drawable/"
        "qa_badge.xml"
    )

    require(
        icon,
        '@mipmap/ic_launcher',
        "base ScratchLess icon",
    )
    require(
        icon,
        '@drawable/qa_badge',
        "QA badge overlay",
    )
    require(
        badge,
        '#FFFF9800',
        "visible QA badge color",
    )
    require(
        badge,
        '#FFFFFFFF',
        "QA badge contrast",
    )

    print("PASS: QA launcher receives a distinct badge.")


def verify_workflow() -> None:
    workflow = read(
        ".github/workflows/android_debug.yml"
    )

    required = {
        "workflow name":
            "name: Android QA and Store Builds",
        "source verifier":
            "python tools/verify_sl77a_qa2.py --ci",
        "QA config test":
            "--dart-define=SCRATCHLESS_BUILD=qa",
        "Store config test":
            "--dart-define=SCRATCHLESS_BUILD=store",
        "QA flavor build":
            "flutter build apk\n"
            "          --flavor qa",
        "Store APK build":
            "flutter build apk\n"
            "          --flavor store",
        "Store AAB build":
            "flutter build appbundle\n"
            "          --flavor store",
        "QA application ID":
            "com.cube23.scratchless.qa",
        "Store application ID":
            "com.cube23.scratchless",
        "QA artifact":
            "name: scratchless-qa-apk",
        "Store APK artifact":
            "name: scratchless-store-apk",
        "Store AAB artifact":
            "name: scratchless-store-aab",
    }

    for label, token in required.items():
        require(workflow, token, label)

    if "scratchless-debug-apk" in workflow:
        fail("Old ambiguous debug artifact remains.")

    print(
        "PASS: CI builds and verifies QA APK, "
        "Store APK, and Store AAB."
    )


def verify_build_test() -> None:
    text = read("test/app_build_config_test.dart")

    required = {
        "expected variable":
            "'EXPECTED_SCRATCHLESS_BUILD'",
        "build-name assertion":
            "expect(AppBuildConfig.buildName, "
            "expectedBuild)",
        "QA assertion":
            "AppBuildConfig.qaToolsEnabled",
        "Store assertion":
            "AppBuildConfig.storeBuild",
    }

    for label, token in required.items():
        require(text, token, label)

    print("PASS: QA and Store compile-time states are tested.")


def verify_historical_verifiers() -> None:
    qa = read("tools/verify_sl77a_qa.py")
    geofence = read(
        "tools/verify_sl77a_qa_geofence1.py"
    )

    require(
        qa,
        "AppBuildConfig.qaToolsEnabled",
        "updated rescue QA verifier",
    )
    require(
        qa,
        "'ScratchLess QA only. Opens the real "
        "rescue screen ",
        "updated rescue QA copy",
    )
    require(
        geofence,
        "AppBuildConfig.qaToolsEnabled",
        "updated geofence verifier",
    )
    require(
        geofence,
        "'Reset alert cooldown for this place'",
        "updated cooldown verifier",
    )

    if "kDebugMode" in qa:
        fail("Historical rescue QA verifier is stale.")

    if "kDebugMode" in geofence:
        fail("Historical geofence verifier is stale.")

    print("PASS: Existing QA verifiers match flavor gating.")


def verify_existing_features() -> None:
    rescue = read(
        "lib/features/live_alert/"
        "live_alert_rescue_screen.dart"
    )
    geofence_test = read(
        "test/live_place_alert_service_test.dart"
    )

    required_rescue = {
        "pause": "'Pause running'",
        "leave": "'You chose to leave'",
        "done": "'Done — keep moving'",
    }

    for label, token in required_rescue.items():
        require(rescue, token, label)

    require(
        geofence_test,
        "'GeofenceAction.enter'",
        "existing geofence parser regression",
    )
    require(
        geofence_test,
        "readGeofenceActionForQa(event)",
        "nested geofence parser regression",
    )

    print(
        "PASS: Existing Rescue and geofence "
        "regressions remain protected."
    )


def main() -> int:
    verify_scope()
    verify_android_flavors()
    verify_build_config()
    verify_qa_gates()
    verify_cooldown_reset()
    verify_qa_icon()
    verify_workflow()
    verify_build_test()
    verify_historical_verifiers()
    verify_existing_features()

    print("SL-77A-QA2 VERIFICATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
