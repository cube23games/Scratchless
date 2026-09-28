#!/usr/bin/env python3
import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ALLOWED = {
    ".github/workflows/android_debug.yml",
    ".gitignore",
    "android/app/build.gradle.kts",
    "tools/verify_sl80a.py",
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
    return {
        line.strip()
        for line in output.splitlines()
        if line.strip()
    }


def tracked_signing_files() -> list[str]:
    output = subprocess.check_output(
        [
            "git",
            "ls-files",
            "*.jks",
            "*.keystore",
            "android/key.properties",
        ],
        cwd=ROOT,
        text=True,
    )
    return [
        line.strip()
        for line in output.splitlines()
        if line.strip()
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()

    if args.ci:
        print("PASS: CI mode skips staged-file scope.")
    else:
        actual = staged_files()

        if actual != ALLOWED:
            fail(
                "staged-file scope mismatch. "
                f"expected={sorted(ALLOWED)} "
                f"actual={sorted(actual)}"
            )

        print("PASS: SL-80A staged-file scope is exact.")

    gradle = (
        ROOT / "android/app/build.gradle.kts"
    ).read_text()

    workflow = (
        ROOT / ".github/workflows/android_debug.yml"
    ).read_text()

    gitignore = (
        ROOT / ".gitignore"
    ).read_text()

    for token in (
        "SCRATCHLESS_STORE_KEYSTORE_PATH",
        "SCRATCHLESS_STORE_KEYSTORE_PASSWORD",
        "SCRATCHLESS_STORE_KEY_ALIAS",
        "SCRATCHLESS_STORE_KEY_PASSWORD",
        "SCRATCHLESS_ALLOW_DEBUG_STORE_CANDIDATE",
        'create("storeRelease")',
        "configuredStoreSigningValues in 1 until storeSigningValues.size",
        "Production Store builds fail closed unless signing is complete.",
        "isStoreReleaseRequested",
    ):
        require(
            gradle,
            token,
            "Gradle signing contract",
        )

    if re.search(
        r'buildTypes\s*\{\s*release\s*\{'
        r'[^}]*signingConfig\s*=\s*'
        r'signingConfigs\.getByName\("debug"\)',
        gradle,
        re.S,
    ):
        fail(
            "release build type still unconditionally "
            "uses debug signing"
        )

    print(
        "PASS: Store release no longer silently "
        "inherits debug signing."
    )

    for token in (
        "SCRATCHLESS_STORE_KEYSTORE_B64",
        "SCRATCHLESS_STORE_KEYSTORE_PASSWORD",
        "SCRATCHLESS_STORE_KEY_ALIAS",
        "SCRATCHLESS_STORE_KEY_PASSWORD",
        "SCRATCHLESS_STORE_CERT_SHA256",
        "Prepare Store signing posture",
        "Incomplete Store signing secret set",
        "SCRATCHLESS_ALLOW_DEBUG_STORE_CANDIDATE=true",
        "Verify Store signing posture",
        "apksigner",
        "openssl pkcs7",
        "openssl x509",
        "META-INF/",
        "Store signing certificate digest mismatch",
        "Store APK and AAB certificate digests do not match",
        "Verify SL-80A signing plumbing",
        "python tools/verify_sl80a.py --ci",
        "scratchless-store-signing-metadata",
    ):
        require(
            workflow,
            token,
            "Workflow signing contract",
        )

    print(
        "PASS: workflow prepares, validates, and "
        "verifies Store signing posture."
    )

    for token in (
        "*.jks",
        "*.keystore",
        "android/key.properties",
    ):
        require(
            gitignore,
            token,
            "Signing ignore contract",
        )

    tracked = tracked_signing_files()

    if tracked:
        fail(
            f"signing material is tracked: {tracked}"
        )

    print(
        "PASS: keystore/key-property material is "
        "excluded from source control."
    )

    literal_patterns = (
        r'storePassword\s*=\s*"[^"]+"',
        r'keyPassword\s*=\s*"[^"]+"',
        r'keyAlias\s*=\s*"[^"]+"',
    )

    for pattern in literal_patterns:
        if re.search(pattern, gradle):
            fail(
                "Gradle contains a literal "
                "signing credential"
            )

    print(
        "PASS: no signing credential values are "
        "embedded in Gradle source."
    )

    print("SL-80A VERIFICATION PASSED")


if __name__ == "__main__":
    main()
