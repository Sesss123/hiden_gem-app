# Security Fix and Validation Report

Date: 2026-10-22

## Scope

This pass addressed the exploitable paths found in the mobile, Firebase, and Laravel security review. It did not build an Android App Bundle and did not perform live penetration testing against production services.

## Fixed

1. Family QR joins now execute inside an App Check protected Cloud Function transaction. Direct client membership updates and open-session enumeration are denied by Firestore rules.
2. Join tokens now use `Random.secure()`. Capacity, expiry, phase, duplicate membership, and tour-link creation are enforced server-side.
3. New trusted-device enrollment and new Zenith session creation require a Firebase ID token with an authentication age of no more than five minutes.
4. Device-account correlation now derives the device hash from the device ID already verified by Zenith middleware. Clients can no longer write arbitrary `device_trust` documents.
5. High and critical security alerts now use App Check protected, rate-limited callables with server-controlled severity. Direct `security_alerts` and `threat_notifications` writes are denied.
6. Review eligibility now requires a real paid, completed booking linked to the completed session and the reviewing tourist.
7. Shared HMAC/AES values were removed from the client trust model. Device ECDSA remains the request-integrity control, and local encryption fails closed if secure device storage is unavailable.
8. The hardcoded iOS Google Maps key was removed. iOS now reads `GOOGLE_MAPS_IOS_API_KEY` from an ignored xcconfig file.
9. Account deletion now removes legacy profile-view markers that identify the deleted guide through `targetUid`.

## Automated Validation

- Flutter tests: 55 passed, 0 failed.
- Firestore rules: 12 passed, 0 failed.
- Storage rules: 4 passed, 0 failed.
- Functions zero-trust tests: 4 passed, 0 failed.
- Laravel tests: 13 passed, 0 failed, 61 assertions.
- Functions TypeScript build: passed.
- Full Flutter static analysis: passed with no issues.
- Changed PHP controllers/configuration: syntax checks passed.

## Deployment Requirements

1. Deploy Cloud Functions and Firestore rules together. The new client join flow depends on the new callable and the rules intentionally reject the old direct-write flow.
2. Enable Firebase App Check enforcement for Cloud Functions, Firestore, and Storage in Firebase Console. Client activation alone is not enforcement.
3. Rotate the previously exposed iOS Google Maps key, restrict the replacement to the iOS bundle ID, and allow only the required Maps APIs.
4. Create `ios/Flutter/GoogleMaps.xcconfig` from `ios/Flutter/GoogleMaps.xcconfig.example` in the release environment.
5. Keep Laravel/Firebase production secrets only in server-side environment or secret-manager configuration.
6. Monitor callable rejection rates, join attempts, security-alert cooldown markers, and Firebase billing alerts after deployment.

## Git Commits

- `631ce4f` - server-authoritative family tour joins
- `aba9cb3` - device trust, session bootstrap, review, and alert hardening
- `f8d85a3` - removal of extractable client secrets and hardcoded iOS Maps key

The commits are local until the repository owner explicitly authorizes pushing them to `origin/main`.
