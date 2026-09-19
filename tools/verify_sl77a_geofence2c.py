#!/usr/bin/env python3
from pathlib import Path
import subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
CI='--ci' in sys.argv
EXPECTED={'.github/workflows/android_debug.yml','lib/core/services/live_place_alert_service.dart','test/live_place_alert_service_test.dart','tools/verify_sl77a_geofence2b.py','tools/verify_sl77a_geofence2c.py'}
def fail(m): print('FAIL:',m); raise SystemExit(1)
def read(p):
    q=ROOT/p
    if not q.is_file(): fail('Missing '+p)
    return q.read_text()
def req(text,token,label):
    if token not in text: fail(f'Missing {label}: {token}')
if not CI:
    r=subprocess.run(['git','diff','--cached','--name-only'],cwd=ROOT,text=True,capture_output=True,check=True)
    changed={x.strip() for x in r.stdout.splitlines() if x.strip()}
    if changed!=EXPECTED: fail(f'Staged scope mismatch. Expected {sorted(EXPECTED)} Found {sorted(changed)}')
    print('PASS: GEOFENCE2C staged-file scope is exact.')
else: print('PASS: CI mode skips staged-file scope.')
service=read('lib/core/services/live_place_alert_service.dart')
tests=read('test/live_place_alert_service_test.dart')
verify_b=read('tools/verify_sl77a_geofence2b.py')
workflow=read('.github/workflows/android_debug.yml')
pubspec=read('pubspec.yaml')
for token,label in {
 'static const int _geofenceProximityRadiusMeters = 5000':'5 km proximity scope',
 'static const bool _geofenceInitialTriggerEntry = true':'initial-entry recovery policy',
 'geofenceProximityRadius: _geofenceProximityRadiusMeters':'Tracelet proximity config',
 'geofenceInitialTriggerEntry: _geofenceInitialTriggerEntry':'Tracelet initial-entry config',
 'geofenceProximityRadiusMetersForQa':'QA proximity getter',
 'geofenceInitialTriggerEntryForQa':'QA initial-entry getter',
}.items(): req(service,token,label)
if 'geofenceInitialTriggerEntry: false' in service: fail('Old initial-entry suppression remains')
if 'geofenceModeHighAccuracy: true' in service: fail('High-accuracy mode must remain off')
for token in ['final existingGeofences = await tl.Tracelet.getGeofences()','if (!alreadyGeofencing)','sameGeofenceDefinitionForQa(existing, place)']:
    req(service,token,'GEOFENCE2B preserve-state behavior')
if 'await tl.Tracelet.removeGeofences();' in service: fail('Blanket removeGeofences() returned')
for token in ['geofence approach policy','keeps monitoring active across a multi-kilometer approach','service.geofenceProximityRadiusMetersForQa','service.geofenceInitialTriggerEntryForQa']:
    req(tests,token,'GEOFENCE2C regression test')
if '"geofenceInitialTriggerEntry: false"' in verify_b: fail('GEOFENCE2B verifier still freezes old policy')
req(workflow,'python tools/verify_sl77a_geofence2c.py --ci','GEOFENCE2C workflow gate')
req(pubspec,'tracelet: 1.8.13','Tracelet pin')
print('PASS: active geofence approach scope is 5000 m.')
print('PASS: legitimate entry can recover after proximity re-registration.')
print('PASS: GEOFENCE2B preserve-state behavior remains required.')
print('PASS: high-accuracy mode remains off for this focused patch.')
print('PASS: Tracelet remains pinned at 1.8.13.')
print('SL-77A-GEOFENCE2C VERIFICATION PASSED')
