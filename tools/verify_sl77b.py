#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv
EXPECTED = {
    ".github/workflows/android_debug.yml",
    "lib/app/scratchless_app.dart",
    "lib/core/models/urge_session_log.dart",
    "lib/core/services/premium_prompt_service.dart",
    "lib/core/services/weekly_summary_service.dart",
    "lib/core/storage/app_storage.dart",
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "lib/features/urge/urge_mode_screen.dart",
    "test/urge_outcome_semantics_test.dart",
    "tools/verify_sl77b.py",
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
    result = subprocess.run(["git", "diff", "--cached", "--name-only"], cwd=ROOT, text=True, capture_output=True, check=True)
    changed = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    if changed != EXPECTED:
        fail(f"Staged scope mismatch.\nExpected: {sorted(EXPECTED)}\nFound: {sorted(changed)}")
    print("PASS: SL-77B staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

model = read("lib/core/models/urge_session_log.dart")
storage = read("lib/core/storage/app_storage.dart")
weekly = read("lib/core/services/weekly_summary_service.dart")
premium = read("lib/core/services/premium_prompt_service.dart")
app = read("lib/app/scratchless_app.dart")
live = read("lib/features/live_alert/live_alert_rescue_screen.dart")
urge = read("lib/features/urge/urge_mode_screen.dart")
tests = read("test/urge_outcome_semantics_test.dart")
workflow = read(".github/workflows/android_debug.yml")

for token, label in {
    "resolvedWithoutPurchase": "resolved outcome",
    "stillDeciding": "deciding outcome",
    "unknownLegacy": "conservative legacy outcome",
    "bool get countsAsUrgeWin": "win semantics",
    "'outcome': _outcomeStorageValue": "outcome persistence",
    "live_alert_rescue_deciding": "legacy deciding migration",
}.items():
    require(model, token, label)

for token, label in {
    "_legacyUrgeWinsBaselineKey": "baseline migration key",
    "storedUrgesDefeated - rawUrgeSessions.length": "aggregate-only baseline migration",
    "await prefs.setInt(\n          _legacyUrgeWinsBaselineKey": "one-time baseline persistence",
}.items():
    require(storage, token, label)

require(weekly, "currentUrges.where((session) => session.countsAsUrgeWin).length", "weekly honest win count")
require(weekly, "previousUrges.where((session) => session.countsAsUrgeWin).length", "previous weekly honest win count")
require(premium, "required int urgeWinsCount", "honest premium prompt input")
if "urgeSessionsCount" in premium:
    fail("Premium prompt still uses raw session count.")

for token, label in {
    "int get _urgesDefeated": "derived honest win total",
    "_legacyUrgeWinsBaseline + explicitWins": "legacy plus explicit win calculation",
    "outcome: UrgeSessionOutcome.resolvedWithoutPurchase": "pre-store explicit success",
    "urgeWinsCount: _urgesDefeated": "premium prompt honest count",
}.items():
    require(app, token, label)
if "_urgesDefeated += 1" in app:
    fail("Unconditional urge-win increment remains.")

require(live, "outcome: UrgeSessionOutcome.resolvedWithoutPurchase", "live-alert resolved outcome")
require(live, "outcome: UrgeSessionOutcome.stillDeciding", "live-alert deciding outcome")
require(urge, "outcome: UrgeSessionOutcome.resolvedWithoutPurchase", "urge-mode resolved outcome")

for token in [
    "legacy live-alert deciding is migrated as not a win",
    "weekly summary excludes still-deciding from wins and cash kept",
    "storage migration preserves aggregate-only wins once",
]:
    require(tests, token, "SL-77B regression test")

require(workflow, "flutter test test/urge_outcome_semantics_test.dart", "SL-77B Flutter test")
require(workflow, "python tools/verify_sl77b.py --ci", "SL-77B verifier gate")

print("PASS: urge sessions now carry explicit outcomes.")
print("PASS: still-deciding sessions remain logged but do not count as wins.")
print("PASS: cash-kept and weekly wins use resolved outcomes only.")
print("PASS: legacy aggregate-only wins are preserved through migration.")
print("PASS: first-win premium prompt uses honest wins.")
print("SL-77B VERIFICATION PASSED")
