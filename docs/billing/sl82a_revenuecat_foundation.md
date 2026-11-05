# SL-82A — RevenueCat + Google Play Billing foundation

## Purpose

Introduce RevenueCat without placing billing work on the
ScratchLess critical launch path.

## RevenueCat authority

- RevenueCat entitlement ID: `premium`.
- Flutter SDK pin: `purchases_flutter 10.19.0`.
- Store uses `REVENUECAT_ANDROID_PUBLIC_SDK_KEY`.
- Only an Android production key beginning with `goog_`
  enables RevenueCat.
- QA remains on the local Premium test scaffold.
- Test Store keys must never activate RevenueCat in a
  Store build.
- Feature screens do not import RevenueCat directly.
- `PremiumState` remains the single app-facing feature
  gate seam.

## Performance guardrails

BreakWave showed why billing must not become startup
authority.

ScratchLess therefore:

1. completes normal local bootstrap first;
2. renders the first Flutter frame;
3. waits briefly;
4. initializes RevenueCat asynchronously;
5. never awaits RevenueCat from `main.dart`;
6. performs no Offering fetch during startup;
7. performs no restore during startup;
8. performs no purchase during startup.

A slow or unavailable RevenueCat service must not prevent
Free ScratchLess from opening.

## Trusted entitlement rule

Trusted Entitlements use informational verification.

Positive Premium access requires:

- the `premium` entitlement exists;
- it is active; and
- the CustomerInfo entitlement response verification is
  `verified`.

The first Store state remains Free until trusted authority
arrives.

## Not included in SL-82A

- no monthly purchase button;
- no annual purchase button;
- no RevenueCat Paywalls UI package;
- no automatic restore;
- no `getOfferings()` call on launch;
- no Google Places change.

Purchase and restore flows are wired only after the
foundation passes CI and startup/device acceptance.

## Dashboard work before purchase activation

Create a separate ScratchLess RevenueCat project for:

`com.cube23.scratchless`

Use entitlement:

`premium`

Monthly and annual Google Play subscription products/base
plans will both grant that same entitlement.
