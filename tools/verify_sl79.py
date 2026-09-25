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
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "test/live_alert_rescue_purchase_recovery_test.dart",
    "test/urge_outcome_semantics_test.dart",
    "tools/verify_sl79.py",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        fail(f"Missing {path}")
    return target.read_text(encoding="utf-8")


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing {label}: {token}")


if not CI_MODE:
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    changed = {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    }
    if changed != EXPECTED:
        fail(
            "Staged scope mismatch. "
            f"Expected {sorted(EXPECTED)}, found {sorted(changed)}"
        )
    print("PASS: SL-79 staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")
model = read("lib/core/models/urge_session_log.dart")
app = read("lib/app/scratchless_app.dart")
live = read("lib/features/live_alert/live_alert_rescue_screen.dart")
semantics = read("test/urge_outcome_semantics_test.dart")
widget = read("test/live_alert_rescue_purchase_recovery_test.dart")
workflow = read(".github/workflows/android_debug.yml")

for token, label in {
    "purchaseOccurred": "purchase outcome enum",
    "purchase_occurred": "purchase outcome storage value",
    "outcome == UrgeSessionOutcome.resolvedWithoutPurchase":
        "win semantics remain resolved-only",
}.items():
    require(model, token, label)

for token, label in {
    "void _logPurchaseAfterLiveAlertRescue({":
        "combined app transaction",
    "final eventTime = session.completedAt;":
        "shared event timestamp",
    "createdAt: eventTime": "purchase timestamp uses session timestamp",
    "_urgeSessions = <UrgeSessionLog>[":
        "urge session persisted with purchase",
    "onLogPurchaseAfterRescue: _logPurchaseAfterLiveAlertRescue":
        "rescue callback wiring",
}.items():
    require(app, token, label)
for token, label in {
    "PurchaseLogSheet(": "real purchase sheet reuse",
    "I bought tickets": "honest purchase choice",
    "live_alert_rescue_purchase": "purchase rescue script id",
    "UrgeSessionOutcome.purchaseOccurred": "purchase outcome logging",
    "Purchase logged — stop the spiral here": "post-purchase recovery feedback",
    "Purchase logged honestly": "purchase counts as a used recovery action",
    "Open full urge tools": "preserved full Urge Mode escalation",
    "Open live support options": "preserved live support escalation",
}.items():
    require(live, token, label)

for token in [
    "purchaseReloaded.outcome, UrgeSessionOutcome.purchaseOccurred",
    "purchaseReloaded.countsAsUrgeWin, isFalse",
    "purchaseReloaded.countsTowardCashKept, isFalse",
    "purchase outcome records spend truth without creating an urge win",
    "expect(summary.purchasesThisWeek, 1)",
    "expect(summary.spentThisWeek, 15)",
    "expect(summary.urgeWinsThisWeek, 0)",
    "expect(summary.cashKeptThisWeek, 0)",
]:
    require(semantics, token, "SL-79 outcome semantics coverage")
for token in [
    "purchase outcome uses real purchase sheet and opens recovery escalation",
    "I bought tickets",
    "Log a scratch-off purchase",
    "Purchase logged — stop the spiral here",
    "Need another layer?",
    "Open full urge tools",
    "Open live support options",
]:
    require(widget, token, "SL-79 widget regression coverage")

require(
    workflow,
    "flutter test test/live_alert_rescue_purchase_recovery_test.dart",
    "SL-79 Flutter widget test gate",
)
require(
    workflow,
    "python tools/verify_sl79.py --ci",
    "SL-79 verifier gate",
)

print("PASS: purchase outcome is explicit and never counts as a win.")
print("PASS: purchase and urge session share one event timestamp.")
print("PASS: Rescue reuses the existing real purchase logger.")
print("PASS: post-purchase recovery exposes existing escalation options.")
print("SL-79 VERIFICATION PASSED")