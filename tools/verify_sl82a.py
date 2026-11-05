#!/usr/bin/env python3

import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ALLOWED = {
    ".github/workflows/android_debug.yml",
    "docs/billing/sl82a_revenuecat_foundation.md",
    "lib/app/scratchless_app.dart",
    "lib/core/config/app_build_config.dart",
    "lib/core/services/revenuecat_billing_service.dart",
    "pubspec.yaml",
    "test/sl82a_revenuecat_foundation_test.dart",
    "tools/verify_sl82a.py",
}


def fail(message):
    raise SystemExit(f"FAIL: {message}")


def require(text, token, label):
    if token not in text:
        fail(f"{label}: missing {token!r}")


def forbid(text, token, label):
    if token in text:
        fail(f"{label}: forbidden token {token!r}")


def staged_files():
    output = subprocess.check_output(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
    )

    return {
        line.strip()
        for line in output.splitlines()
        if line.strip()
    }


def workflow_step(text, name):
    marker = f"      - name: {name}\n"

    start = text.find(marker)

    if start < 0:
        fail(f"workflow step missing: {name}")

    end = text.find(
        "\n      - name:",
        start + len(marker),
    )

    if end < 0:
        end = len(text)

    return text[start:end]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()

    if not args.ci:
        actual = staged_files()

        if actual != ALLOWED:
            fail(
                "staged-file scope mismatch. "
                f"expected={sorted(ALLOWED)} "
                f"actual={sorted(actual)}"
            )

        print(
            "PASS: SL-82A staged-file scope is exact."
        )
    else:
        print(
            "PASS: CI mode skips staged-file scope."
        )

    pubspec = (ROOT / "pubspec.yaml").read_text()

    config = (
        ROOT /
        "lib/core/config/app_build_config.dart"
    ).read_text()

    app = (
        ROOT /
        "lib/app/scratchless_app.dart"
    ).read_text()

    service = (
        ROOT /
        "lib/core/services/"
        "revenuecat_billing_service.dart"
    ).read_text()

    main_dart = (
        ROOT /
        "lib/main.dart"
    ).read_text()

    workflow = (
        ROOT /
        ".github/workflows/android_debug.yml"
    ).read_text()

    require(
        pubspec,
        "  purchases_flutter: 10.19.0",
        "RevenueCat SDK pin",
    )

    forbid(
        pubspec,
        "purchases_ui_flutter:",
        "ScratchLess custom paywall architecture",
    )

    for token in (
        "REVENUECAT_ANDROID_PUBLIC_SDK_KEY",
        "startsWith('goog_')",
        "storeBuild && revenueCatAndroidKeyLooksProduction",
    ):
        require(
            config,
            token,
            "RevenueCat Store policy",
        )

    for token in (
        "premiumEntitlementId = 'premium'",
        "Purchases.setLogLevel",
        "Purchases.configure",
        "addCustomerInfoUpdateListener",
        "getCustomerInfo().timeout",
        "EntitlementVerificationMode.informational",
        "VerificationResult.verified",
    ):
        require(
            service,
            token,
            "RevenueCat authority bridge",
        )

    forbid(
        service,
        "Purchases.logLevel =",
        "RevenueCat 10.x logging API",
    )

    for forbidden in (
        "Purchases.getOfferings",
        "Purchases.restorePurchases",
        "Purchases.purchase(",
        "Purchases.purchasePackage",
        "Purchases.purchaseProduct",
    ):
        forbid(
            service,
            forbidden,
            "SL-82A startup bridge",
        )

    for token in (
        "addPostFrameCallback",
        "Duration(milliseconds: 350)",
        "unawaited(",
        "RevenueCatBillingService.instance.initialize",
        "_applyRevenueCatPremiumEntitlement",
    ):
        require(
            app,
            token,
            "non-blocking RevenueCat startup",
        )

    forbid(
        app,
        "await RevenueCatBillingService.instance.initialize",
        "ScratchLess launch path",
    )

    forbid(
        main_dart,
        "RevenueCatBillingService",
        "main.dart launch path",
    )

    forbid(
        main_dart,
        "purchases_flutter",
        "main.dart launch path",
    )

    for feature in (
        ROOT /
        "lib/features"
    ).rglob("*.dart"):
        forbid(
            feature.read_text(),
            "package:purchases_flutter",
            f"feature screen {feature.relative_to(ROOT)}",
        )

    qa_build = workflow_step(
        workflow,
        "Build QA release APK",
    )

    store_apk = workflow_step(
        workflow,
        "Build Store release APK",
    )

    store_aab = workflow_step(
        workflow,
        "Build Store release AAB",
    )

    forbid(
        qa_build,
        "REVENUECAT_ANDROID_PUBLIC_SDK_KEY",
        "QA APK build",
    )

    for label, block in (
        ("Store APK", store_apk),
        ("Store AAB", store_aab),
    ):
        require(
            block,
            "REVENUECAT_ANDROID_PUBLIC_SDK_KEY",
            label,
        )

        require(
            block,
            "--dart-define=REVENUECAT_ANDROID_PUBLIC_SDK_KEY=",
            label,
        )

    for token in (
        "Test SL-82A RevenueCat policy - QA",
        "Test SL-82A RevenueCat policy - Store no key",
        "Test SL-82A RevenueCat policy - Store Test Store key",
        "Test SL-82A RevenueCat policy - Store configured",
        "Verify SL-82A RevenueCat foundation",
        "test/sl82a_revenuecat_foundation_test.dart",
        "python tools/verify_sl82a.py --ci",
    ):
        require(
            workflow,
            token,
            "SL-82A CI contract",
        )

    if args.ci:
        lock = (ROOT / "pubspec.lock").read_text()

        match = re.search(
            r"purchases_flutter:\n"
            r"(?:.*\n){0,10}?"
            r"\s+version: \"10\.19\.0\"",
            lock,
        )

        if match is None:
            fail(
                "CI dependency resolution did not pin "
                "purchases_flutter 10.19.0"
            )

    print("SL-82A VERIFICATION PASSED")


if __name__ == "__main__":
    main()
