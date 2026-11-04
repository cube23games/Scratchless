#!/usr/bin/env python3
import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {
    ".github/workflows/android_debug.yml",
    "lib/app/scratchless_app.dart",
    "lib/core/config/app_build_config.dart",
    "lib/core/services/feature_gate_service.dart",
    "lib/core/services/premium_prompt_service.dart",
    "lib/features/onboarding/onboarding_screen.dart",
    "lib/features/premium/premium_screen.dart",
    "lib/features/profile/profile_screen.dart",
    "lib/features/risky_places/risky_places_screen.dart",
    "test/sl81d_store_surface_test.dart",
    "tools/verify_sl81d.py",
}

def fail(msg):
    raise SystemExit(f"FAIL: {msg}")

def req(text, token, label):
    if token not in text:
        fail(f"{label}: missing {token!r}")

def forbid(text, token, label):
    if token in text:
        fail(f"{label}: forbidden {token!r}")

def staged():
    out = subprocess.check_output(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
    )
    return {x.strip() for x in out.splitlines() if x.strip()}

def workflow_step(text, name):
    marker = f"      - name: {name}\n"
    start = text.find(marker)
    if start < 0:
        fail(f"workflow step missing: {name}")
    end = text.find("\n      - name:", start + len(marker))
    return text[start: len(text) if end < 0 else end]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()

    if not args.ci:
        actual = staged()
        if actual != ALLOWED:
            fail(f"staged-file scope mismatch: {sorted(actual)}")
    print("PASS: SL-81D scope gate.")

    config = (ROOT / "lib/core/config/app_build_config.dart").read_text()
    app = (ROOT / "lib/app/scratchless_app.dart").read_text()
    gate = (ROOT / "lib/core/services/feature_gate_service.dart").read_text()
    prompts = (ROOT / "lib/core/services/premium_prompt_service.dart").read_text()
    onboarding = (ROOT / "lib/features/onboarding/onboarding_screen.dart").read_text()
    premium = (ROOT / "lib/features/premium/premium_screen.dart").read_text()
    profile = (ROOT / "lib/features/profile/profile_screen.dart").read_text()
    risky = (ROOT / "lib/features/risky_places/risky_places_screen.dart").read_text()
    workflow = (ROOT / ".github/workflows/android_debug.yml").read_text()

    for token in (
        "localPremiumTrialEnabled = qaToolsEnabled",
        "deferredPlaceSearchVisible = qaToolsEnabled",
        "internalDiagnosticsVisible = qaToolsEnabled",
    ):
        req(config, token, "build policy")

    for token in (
        "shouldClearSimulatedPremium",
        "!AppBuildConfig.localPremiumTrialEnabled",
        "PremiumState.free()",
    ):
        req(app, token, "app entitlement cleanup")

    req(gate, "'Premium coming soon'", "Premium CTA")
    forbid(
        prompts,
        "AppBuildConfig",
        "generic Premium prompt service",
    )

    prompt_calls = list(
        re.finditer(
            r"PremiumPromptService\.canShow\s*\(",
            app,
        )
    )

    if len(prompt_calls) != 2:
        fail(
            "ScratchLessApp must contain exactly two Premium prompt "
            f"call sites; found {len(prompt_calls)}"
        )

    for call in prompt_calls:
        prefix = app[max(0, call.start() - 220):call.start()]
        if "AppBuildConfig.localPremiumTrialEnabled" not in prefix:
            fail(
                "each ScratchLessApp Premium prompt call must be "
                "gated by localPremiumTrialEnabled"
            )

    for token in (
        "if (AppBuildConfig.localPremiumTrialEnabled)",
        "_finishOnboarding();",
        "Enable QA Premium",
        "No Google Play purchase occurs",
    ):
        req(onboarding, token, "onboarding separation")

    for token in (
        "!AppBuildConfig.localPremiumTrialEnabled",
        "Premium subscriptions are not available yet",
        "QA can unlock Premium locally for testing",
        "Live Risky Place alerts",
    ):
        req(premium, token, "Premium cleanup")
    forbid(premium, "Billing is not wired yet", "Premium screen")
    forbid(premium, "soft upgrade scaffold", "Premium screen")
    forbid(profile, "premium scaffolding", "Profile screen")

    for token in (
        "Premium coming soon",
        "Premium subscriptions will be added through Google Play",
    ):
        req(profile, token, "Profile cleanup")

    for token in (
        "AppBuildConfig.deferredPlaceSearchVisible",
        "if (!AppBuildConfig.deferredPlaceSearchVisible)",
        "Use your current spot or enter coordinates manually.",
        "AppBuildConfig.internalDiagnosticsVisible",
        "saved places still need setup",
    ):
        req(risky, token, "Risky Places cleanup")

    qa = workflow_step(workflow, "Build QA release APK")
    store_apk = workflow_step(workflow, "Build Store release APK")
    store_aab = workflow_step(workflow, "Build Store release AAB")
    req(qa, "GOOGLE_PLACES_API_KEY", "QA build")
    forbid(store_apk, "GOOGLE_PLACES_API_KEY", "Store APK")
    forbid(store_aab, "GOOGLE_PLACES_API_KEY", "Store AAB")

    for token in (
        "Test SL-81D Store surface policy - QA",
        "Test SL-81D Store surface policy - Store",
        "Verify SL-81D Store cleanup contract",
        "test/sl81d_store_surface_test.dart",
        "python tools/verify_sl81d.py --ci",
    ):
        req(workflow, token, "CI contract")

    print("SL-81D VERIFICATION PASSED")

if __name__ == "__main__":
    main()
