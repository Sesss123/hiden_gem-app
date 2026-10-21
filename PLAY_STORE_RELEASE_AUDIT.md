# Hidden Gems SL — Store Release Audit

Audit date: 2026-10-20

## Scope

This audit covers the Flutter application, Android and iOS configuration, Firebase rules, public policy pages, Laravel moderation tools, and store-listing assets.

An Android App Bundle was intentionally **not built** during this audit. Any existing `.aab` must not be treated as newly validated against these changes.

## Code Fixes Completed

- Android now uses `targetSdk = 36` and `minSdk = 28` without root Gradle overrides that silently lowered the final values.
- Android permissions contain no background location, SMS, Call Log, contacts, `QUERY_ALL_PACKAGES`, or broad storage permission.
- The iOS background-location purpose string was removed because the app only implements while-in-use location.
- The placeholder iOS Google callback URL scheme was removed.
- Google Sign-In is hidden on iOS until a real Firebase iOS client configuration is added; Sign in with Apple remains available on iOS.
- Sign in with Apple entitlement is present for iOS.
- New tour reviews are saved as `under_review` and are not publicly visible until an administrator approves them.
- Review creation rules validate ownership, session eligibility, rating ranges, comment length, and pending moderation state.
- Review updates are admin-only, preventing users from changing protected review ownership or moderation fields after submission.
- Guide broadcasts now have local objectionable-content filtering, a 500-character limit, error handling, and strict Firestore field/type validation.
- Report and block controls were added for supported user-generated-content surfaces.
- Firestore block records are private to the blocker/admin and booking creation enforces mutual blocks.
- AI itinerary, recommendation, translation, Oracle, and food-scan outputs have an in-app reporting action.
- Abuse and AI report writes are schema-limited and visible only to administrators.
- Laravel now includes a Safety Reports moderation queue with resolve/dismiss actions and admin audit logging.
- The public Terms document describes prohibited content, reporting, blocking, moderation, and AI-output reporting.
- The public privacy policy was expanded to cover the app's actual account, location, media, AI, analytics, advertising, purchase, safety, and deletion data flows.
- In-app account deletion and the external deletion page are present in the project.
- Firebase Hosting rewrites `/delete-account` to the deletion page.
- Storage deletion rules were corrected for owner-controlled files.
- Release RevenueCat logging no longer uses debug verbosity.
- The Play Store update URL uses the Android application ID `com.hidden.gems.hidden_gems_sl`.
- Share links use Firebase Hosting instead of an unresolved custom domain.
- Feature graphic was flattened to an opaque 24-bit PNG.

## Store Assets Checked

| Asset | Result | File |
|---|---|---|
| Play icon | Ready, 512×512 PNG | `store_listing/app-icon-512.png` |
| Feature graphic | Ready, 1024×500 opaque 24-bit PNG | `store_listing/feature-graphic-1024x500.png` |
| Phone screenshots | Ready, four 1080×2160 images | `store_listing/screenshots/` |
| Raw captures | Keep as source only; do not upload oversized full-page captures | `store_listing/actual-screenshots/` |
| Android App Bundle | Not rebuilt by this audit | Build only after final configuration and tests |

## Validation Completed

- `php -l` passes for the new safety controller, review controller, and route file.
- All seven Dart files changed in the final compliance pass parse successfully; targeted analysis reports no remaining issues.
- `Info.plist` and `PrivacyInfo.xcprivacy` parse as valid XML.
- `git diff --check` passes with no whitespace errors.
- No placeholder iOS Google callback or always-location purpose key remains in `Info.plist`.
- Android source configuration confirms API 36 target and API 28 minimum.
- Store asset dimensions and feature-graphic pixel format were verified locally.

## Validation Limitations

- Full-project `flutter analyze --no-pub --no-fatal-infos` did not return before the environment timeout, although targeted analysis of every Dart file changed in the final compliance pass succeeded. Rerun the full analyzer locally or in CI before release.
- Laravel route boot/tests cannot run on this machine because its PHP is 8.0.30 while installed Composer dependencies require PHP 8.4.1 or newer. File-level PHP syntax checks passed.
- Firebase rules were reviewed statically; run Firestore/Storage emulator tests before production deployment.
- No `.aab` or iOS archive was built, signed, or uploaded during this audit.
- The hosted privacy and deletion URLs could not be rechecked from the restricted audit environment. Verify them in a normal browser before entering them in either store console.

## Required External Actions

### Firebase and Backend

- Deploy `firebase.json`, `firestore.rules`, `storage.rules`, and the files in `web/`.
- Deploy the Laravel safety-report controller, routes, and views using PHP 8.4.1+.
- Confirm `https://tripme-89742.web.app/privacy` loads publicly over HTTPS.
- Confirm `https://tripme-89742.web.app/delete-account` loads publicly and lets a user initiate deletion without reinstalling the app.
- Restrict the Android and iOS Google Maps API keys by package/bundle ID and signing certificate where applicable.

### Google Play Console

- App access: provide a permanent reviewer account and precise navigation instructions because core features require login.
- Ads: select **Yes, my app contains ads**.
- Data safety: declare all collected/shared data, including account details, phone number, precise/approximate location, photos, audio, messages, AI inputs/outputs, purchases, device/advertising IDs, analytics, crash data, and safety reports.
- Account deletion: enter the working public deletion URL and confirm the in-app deletion path.
- Target audience: select only the intended teen/adult age groups; do not select children unless the entire app and ad stack are made Families-compliant.
- Content rating: disclose UGC, user communications, live-location/safety features, ads, marketplace/bookings, and AI-generated content.
- App content: complete permission, advertising ID, and any financial-feature declarations shown for the final bundle.
- Upload the newly built signed AAB to Internal testing first, then complete automated and manual pre-launch checks.

### Apple App Store Connect

- Add the real `GoogleService-Info.plist` and URL scheme before re-enabling Google Sign-In on iOS; otherwise keep it hidden.
- Confirm Sign in with Apple capability and production authentication behavior.
- Complete App Privacy labels so they match the public privacy policy and actual SDK behavior.
- Complete age rating, advertising/tracking declarations, export compliance, and review notes.
- Provide a working reviewer account and explain location, camera, microphone, calendar, notifications, subscriptions, AI, and UGC/reporting flows.
- Confirm ATT/UMP behavior on a clean device and that non-personalized ads remain available when tracking consent is denied where supported.

## Final Release Gate

Do not submit to production until all of the following pass:

1. Hosted privacy and deletion URLs work publicly.
2. Firebase rules and Laravel moderation changes are deployed.
3. Flutter analyzer/tests and Laravel tests pass in supported environments.
4. A fresh signed AAB and iOS archive are built from the final code.
5. Internal testing verifies login, deletion, permissions, purchases, ads/consent, UGC moderation, reporting/blocking, and AI reporting.
6. Play Console and App Store Connect declarations exactly match the final app behavior.

## Official References

- Google Play target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play account deletion: https://support.google.com/googleplay/android-developer/answer/13327111
- Google Play Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play AI-generated content: https://support.google.com/googleplay/android-developer/answer/13985936
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple privacy manifests: https://developer.apple.com/documentation/BundleResources/privacy-manifest-files
- Apple privacy and data use: https://developer.apple.com/app-store/user-privacy-and-data-use/
