# Hidden Gems SL Publish Checklist

## Blocking items

- Replace the placeholder RevenueCat Android and iOS API keys in `dart_define_prod.json`.
- Replace the placeholder weather API key in `dart_define_prod.json`.
- Replace `APP_STORE_ID` with the real Apple App Store ID.
- Rotate production cryptographic secrets if any local build logs have been shared.
- Resolve the reported Laravel dependency security advisories using a PHP 8.4-compatible environment.
- Replace or disable placeholder AI responses before advertising those features as production-ready.

## Android release

- Confirm `android/key.properties` and `android/app/upload-keystore.jks` are backed up securely and remain untracked.
- Increment `version` in `pubspec.yaml` for every store upload.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Target appbundle`.
- Verify `build/app/outputs/bundle/release/app-release.aab` and archive `symbols/appbundle`.
- Complete Play Console Data safety, content rating, ads, location, camera, microphone, notifications, and account-deletion disclosures.

## iOS release

- Confirm the bundle ID, signing team, certificates, and provisioning profile in Xcode.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_release.ps1 -Target ipa` on macOS.
- Archive `symbols/ipa` and upload the signed IPA through Xcode or Transporter.
- Complete App Store privacy nutrition labels and account-deletion disclosures.

## Final verification

- Test sign-up, sign-in, password reset, sign-out, and account deletion on production services.
- Test purchases and restore purchases with store sandbox accounts.
- Test maps, location permission denial, weather, ads, notifications, QR/camera, and offline/error states.
- Verify privacy policy and terms URLs are publicly reachable.
- Run backend tests and dependency audits immediately before submission.
