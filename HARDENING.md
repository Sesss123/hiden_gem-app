# Zenith Stress Defense: Production Hardening Guide 🛡️

This guide outlines the mandatory steps to achieve **"Titanium Level"** security for release builds, protecting against reverse engineering and tempering.

## 1. Release Build Obfuscation (Point 3)
Obfuscation makes your code nearly impossible to read after decompiling by renaming classes and methods to random characters (e.g., `_a`, `_b`).

**Mandatory Build Command:**
```bash
# For Android APK
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# For Android App Bundle (Recommended for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# For iOS
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

> [!IMPORTANT]
> Keep the `build/app/outputs/symbols` directory safe. You will need the files inside to de-obfuscate stack traces from Crashlytics if your app crashes.

---

## 2. Android R8 Shrinking & Minification
R8 removes unused code and resources, significantly shrinking the APK and making it harder to analyze.

1. Open `android/app/build.gradle`.
2. Ensure `minifyEnabled` and `shrinkResources` are set to `true`:

```gradle
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 3. Package Identity Check (Point 4)
The `IntegrityShield` service checks if the app is running under the correct package name.

- **Current Verified Name:** `com.hidden.gems.hidden_gems_sl`
- **Current Signature Check:** Placeholder (Requires production SHA-256).

### To set your Production Signature:
1. Run this command on your machine to get your SHA-256:
   `keytool -list -v -keystore your_keystore_path.jks`
2. Update `lib/core/services/integrity_shield.dart` line 26:
   `static const String _expectedSignatureHash = 'YOUR_SHA256_HERE';`

---

## 4. App Check Enforcement (Point 1)
App Check is already integrated in the code via `AppCheckConfig`.

1. Go to **Firebase Console** → **App Check**.
2. Register **Play Integrity** for Android and **DeviceCheck** for iOS.
3. **DO NOT** press "Enforce" immediately.
4. Wait 24-48 hours. Look at the "Requests" tab.
5. Once you see that genuine requests are being verified, press **Enforce**.

---

## 5. Security Response Ladder (Point 4)
The system is designed with a non-binary defense.

- **Risk 0-29**: Normal usage.
- **Risk 30-59**: Admin features restricted.
- **Risk 60-89**: Premium features restricted + **Force Re-auth**.
- **Risk 90+**: Session Quarantined + Server actions denied.

---

## 6. Network Layer Hardening 🌐
To prevent Man-In-The-Middle (MITM) and Replay attacks, we have implemented several network-layer defenses.

### SSL Pinning (Point 1)
Specific high-value hostnames now require their SSL leaf certificate to match a pinned fingerprint.

**To get a server's fingerprint:**
Run this in your terminal:
```bash
openssl s_client -connect api.yourserver.com:443 < /dev/null 2>/dev/null | openssl x509 -outform DER | openssl dgst -sha256
```
**To configure pins:**
Update `lib/core/network/secure_network.dart` in the `_pinnedHosts` map.

### HMAC Request Signing & Replay Protection
Every request made via `SecureHttpClient` automatically includes:
- `X-Zenith-Timestamp`: Current UTC time.
- `X-Zenith-Nonce`: A random UUID.
- `X-Zenith-Signature`: HMAC-SHA256 hash of the request metadata and body.

**To configure your Shared Secret:**
The signature is generated using a secret key. In production, pass this key when initializing your services:
```dart
final client = SecureHttpClient(http.Client(), sharedSecret: 'YOUR_PRODUCTION_SECRET');
```

**What this protects against:**
1. **MITM Tampering**: If an attacker modifies the request body, the backend signature check will fail.
2. **Replay Attacks**: Because each request has a unique `Nonce`, the backend can reject duplicate requests within a timestamp window.
---

## 7. Split Architecture Hardening 🧩
To confuse and defeat reverse engineers, the "isPremium" boolean has been eliminated as a single point of failure.

### The Security Nexus (5 Keys)
The [SecurityOrchestrator](file:///c:/Users/sehas/antigravity/scratch/hidden_gems_sl/lib/core/services/security_orchestrator.dart) requires 5 independent keys to unlock features:
1. **Local Key**: Boolean flag in the encrypted profile.
2. **Server Key**: Direct real-time proof from Firestore.
3. **Integrity Key**: Low risk score requirement (No root/emulator).
4. **Session Key**: Healthy account status (Not quarantined).
5. **Crypto Key**: HMAC-SHA256 signature verification of the expiry date.

### UI Fragmentation
Guards are scattered across the UI in multiple files. An attacker patching one file (e.g., removing a lock icon) will find that the button click still fails because of a secondary check in the navigation logic, or the data fetch fails because of a third check in the repository layer.

---

## 8. Panic Room (Emergency Controls) 🚨
During an active attack, we can remotely disable app features without a store update.

### Emergency Controls (Remote Config)
You must set up these keys in **Firebase Console** → **Remote Config**:
- `kill_switch_active` (Boolean): Blocks all access if the app/infrastructure is fully compromised.
- `slow_mode_enabled` (Boolean): Adds artificial latency to throttle automated attack scripts.
- `min_app_version` (String): Blocks outdated versions that may have unpatched security holes.
- `disabled_features` (JSON Array): e.g., `["ai_trip", "marketplace_search"]`.

### Monitoring (Analytics)
Security events (Root detected, Signatures mismatch, Panic Room triggers) are logged silently to the `security_events` collection in Firestore. Monitor this for spikes in unusual activity.

---

## 9. Forensic Risk Scoring 🧠
The system uses a non-binary, multi-signal approach to detect tampered devices.

| Signal | Risk Points | Response |
| :--- | :--- | :--- |
| Root / Jailbreak | 50 pts | Medium Risk (Feature Gating) |
| Debugger Attached | 40 pts | Medium Risk (Admin Block) |
| Emulator / Simulator | 30 pts | Low-Medium Risk |
| App Check Verification Fail| 30 pts | Low-Medium Risk |
| Dev Mode / ADB Enabled | 10 pts | Logging only |

---

## 10. Military-Grade Forensic Trail 📸🕵️
The app records a structured, tamper-proof "Black Box" of forensic data for every security anomaly.

### Forensic Payload (Structured context)
Every record in the `security_events` collection includes:
- **Device Hash**: Unique (non-PII) identity of the hardware.
- **Hashed IP**: Salted HMAC of the source network (for correlation).
- **Integrity Verdict**: Comprehensive risk score and active signals.
- **Impossible Patterns**: Detections like "Admin probe from High-Risk device".

### Incident Response (Step-Logic Thresholds)
We monitor token failures and access attempts using a 10-minute sliding window:

| Attempts | Severity | Admin Response |
| :--- | :--- | :--- |
| 3 / 10m| Medium | Forensic Log only |
| 5 / 10m| High | **Push Notification** (Deduplicated) |
| 8+ / 10m| Critical| **Immediate Push** + Auto-Quarantine |

### Admin Push Policy (FCM)
Admin alerts are escalated based on severity:
- **Topic**: `security-admins`
- **Critical**: Dispitched immediately to all admins.
- **High**: Grouped and rate-limited (10-minute deduplication) to prevent alert fatigue.
- **Medium/Low**: Dashboard visibility only.

### Tamper-Resistance
Firestore rules ensure that forensic trails are **Immutable**. A user/attacker can `create` a security event, but they can never `update` or `delete` it.
