# ScratchLess — Background Location Submission Package (SL-81C)

## Declared background-location feature

**Feature:** Live Risky Places

ScratchLess lets a user save places that are personally risky for scratch-off or lottery purchases and opt individual places into Live Risky Place alerts. Background location is used so the device can recognize an approach to an opted-in risky place when ScratchLess is closed or not in use and trigger a timely support alert before a purchase becomes automatic.

This is the single feature declared for background location.

## Core-functionality justification

ScratchLess is a lottery-urge recovery and relapse-prevention app. A high-risk moment often occurs before the user opens the app: while approaching a store or other place associated with buying tickets. Live Risky Places moves the intervention into that moment by alerting the user at a place they explicitly chose. Foreground-only location cannot provide the same timely intervention after the app has been closed or moved to the background.

Background location is optional. Users who decline it can continue using the rest of ScratchLess, but Live Risky Place monitoring cannot operate while the app is closed or not in use.

## Prominent in-app disclosure

**Title:** Background location for Live Risky Places

**Disclosure:**

> ScratchLess accesses location data to enable Live Risky Place alerts even when the app is closed or not in use. Your location is compared with risky places you choose so ScratchLess can alert you before a risky stop. ScratchLess does not use location for advertising.

Actions: **Not now** and **Continue**.

The disclosure appears in the normal Live Risky Places setup flow immediately before the app requests location permission. Dismissing the dialog, pressing Back, or choosing Not now does not trigger a permission request.

## Permission sequence

1. User explicitly configures a risky place and enables Live Risky Place alerts.
2. ScratchLess displays the prominent background-location disclosure.
3. User taps Continue.
4. ScratchLess requests/checks foreground location access first.
5. If foreground access is not granted, setup stops and live monitoring remains off.
6. If foreground access is granted but background access is not, ScratchLess opens the app's Android settings page and instructs the user to choose **Allow all the time**.
7. ScratchLess verifies background access before arming live geofences.

## Suggested Play Console declaration answer

ScratchLess uses background location for Live Risky Places, a relapse-prevention feature. Users explicitly save and opt specific risky stores/places into monitoring. Background access lets ScratchLess detect approach to those user-selected places and send a support alert even when the app is closed or not in use. Without background access, the alert cannot occur at the high-risk moment unless the user already has ScratchLess open.

## Store listing copy to add before submission

**Live Risky Places:** Save stores or places that tend to trigger ticket purchases. If you choose to enable Live Risky Place alerts and allow background location, ScratchLess can alert you as you approach those saved places even when the app is closed or not in use.

## Website privacy-policy section

### Location data and Live Risky Places

ScratchLess accesses location data only when you use location-based features. If you opt into Live Risky Places, ScratchLess may access location in the background — including when the app is closed or not in use — so it can compare your device location with risky places you have chosen and trigger a support alert when you approach one. Background location is optional and is not used for advertising. You can turn Live Risky Place alerts off for individual places or change ScratchLess location permission in Android settings at any time.

Before Play submission, publish this language on the active ScratchLess privacy-policy URL and ensure the URL is linked both in Google Play and from the app.

## Reviewer video — target 30 seconds or less

1. **0–5 sec:** Open ScratchLess → Risky Places; show a saved place with Live place alerts enabled.
2. **5–10 sec:** Tap the setup action that begins Android location access.
3. **10–16 sec:** Show the prominent disclosure in full, including “location” and “even when the app is closed or not in use.”
4. **16–22 sec:** Tap Continue and show the Android foreground-location prompt or current foreground permission state.
5. **22–26 sec:** Show the Android app-location settings page and the **Allow all the time** option.
6. **26–30 sec:** Return to ScratchLess and show Live alert status as ready/armed. If practical, also show the effect of a background-triggered test alert in QA.

The video must be captured on Android and must show the same UI submitted for review.

## Reviewer navigation instructions

1. Open ScratchLess.
2. Complete onboarding if shown.
3. Open Risky Places.
4. Add or edit a risky place, save a location, and turn on Live place alerts.
5. Use the Live alert setup action.
6. Review the prominent location disclosure and tap Continue.
7. Grant foreground location if requested.
8. In Android app settings, choose Allow all the time.
9. Return to ScratchLess and use Refresh live alert status to confirm the place is armed.

## Privacy/Data Safety verification before submission

- Confirm the production build's third-party location/geofence SDK behavior before answering Google Play Data Safety questions about whether location leaves the device.
- Do not claim that location is never transmitted off-device until that SDK/network behavior has been independently verified.
- Keep the Store description, in-app disclosure, website privacy policy, Permissions Declaration Form, and reviewer video consistent with the shipped behavior.
- If background location is removed later, remove `ACCESS_BACKGROUND_LOCATION` from every active APK/AAB track and update the declaration.

## Source-of-truth policy references

- Google Play Console Help: Understanding location in the background permissions
  https://support.google.com/googleplay/android-developer/answer/9799150
- Android Developers: Request background location
  https://developer.android.com/develop/sensors-and-location/location/permissions/background
- Android Developers: Request location access at runtime
  https://developer.android.com/develop/sensors-and-location/location/permissions/runtime
