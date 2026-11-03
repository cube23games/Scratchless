#!/usr/bin/env python3
import argparse, re, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {".github/workflows/android_debug.yml", "android/app/build.gradle.kts", "tools/verify_sl81b_qa_signing.py"}
def fail(m): raise SystemExit(f"FAIL: {m}")
def require(t, n, l):
    if n not in t: fail(f"{l}: missing {n!r}")
def staged():
    out = subprocess.check_output(["git","diff","--cached","--name-only"], cwd=ROOT, text=True)
    return {x.strip() for x in out.splitlines() if x.strip()}
def main():
    p=argparse.ArgumentParser(); p.add_argument("--ci",action="store_true"); a=p.parse_args()
    if not a.ci:
        s=staged()
        if s != ALLOWED: fail(f"staged scope mismatch expected={sorted(ALLOWED)} actual={sorted(s)}")
        print("PASS: stable QA signing staged scope exact.")
    else: print("PASS: CI mode skips staged scope.")
    g=(ROOT/"android/app/build.gradle.kts").read_text(); w=(ROOT/".github/workflows/android_debug.yml").read_text()
    for n in ("SCRATCHLESS_QA_KEYSTORE_PATH","SCRATCHLESS_QA_KEYSTORE_PASSWORD","SCRATCHLESS_QA_KEY_ALIAS","SCRATCHLESS_QA_KEY_PASSWORD",'create("qaRelease")',"isQaReleaseRequested","Stable QA release builds fail closed.",'signingConfigs.getByName("qaRelease")'):
        require(g,n,"Gradle QA signing")
    if re.search(r'create\("qa"\)\s*\{.*?signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',g,re.S): fail("QA flavor still unconditionally uses Android Debug signing")
    for n in ("SCRATCHLESS_QA_KEYSTORE_B64","SCRATCHLESS_QA_CERT_SHA256","Prepare QA signing posture","Complete stable QA signing secrets are required; refusing to build.","Verify QA signing posture","QA signing certificate digest mismatch.","Stable QA build unexpectedly uses Android Debug signing.","mode=stable-qa","scratchless-qa-signing-metadata","python tools/verify_sl81b_qa_signing.py --ci"):
        require(w,n,"Workflow QA signing")
    print("PASS: stable QA signing is fail-closed and certificate-verified.")
    print("SL-81B STABLE QA SIGNING VERIFICATION PASSED")
if __name__ == "__main__": main()
