#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
service = (root / "lib/core/services/support_link_service.dart").read_text()
screen = (root / "lib/features/help/help_screen.dart").read_text()
workflow = (root / ".github/workflows/android_debug.yml").read_text()

errors = []

def require(text, needle, label):
    if needle not in text:
        errors.append(f"missing {label}: {needle!r}")

def forbid(text, needle, label):
    if needle in text:
        errors.append(f"forbidden {label}: {needle!r}")

require(service, "gamblingDialDigits = '18006973738'", "MY-RESET numeric destination")
require(service, "crisis988CallUri", "988 call URI")
require(service, "crisis988TextUri", "988 text URI")
require(service, "emergency911CallUri", "911 call URI")
require(service, "https://www.ncpgambling.org/chat/", "NCPG chat URL")

require(screen, "Text 1-800-MY-RESET", "current NCPG text label")
require(screen, "24/7/365", "NCPG availability")
require(screen, "It is not an emergency crisis line.", "gambling/crisis distinction")
require(screen, "Crisis or immediate danger", "crisis section")
require(screen, "Call 988", "988 call action")
require(screen, "Text 988", "988 text action")
require(screen, "Call 911", "911 action")

forbid(service, "800426", "obsolete 800GAM SMS destination")
forbid(screen, "800GAM", "obsolete 800GAM UI copy")

require(
    workflow,
    "flutter test test/help_safety_accuracy_test.dart",
    "SL-81B Flutter test gate",
)
require(
    workflow,
    "python tools/verify_sl81b.py --ci",
    "SL-81B source contract gate",
)

if errors:
    print("SL-81B verification FAILED")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("SL-81B verification PASS")
