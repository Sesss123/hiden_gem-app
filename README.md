# 🌴 Hidden Gems Sri Lanka (hidden_gems_sl)

[![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.3.0-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-%5E3.0.0-cyan.svg?logo=dart)](https://dart.dev)
[![Firebase Supported](https://img.shields.io/badge/Firebase-Core%20%26%20Firestore-orange.svg?logo=firebase)](https://firebase.google.com)
[![Platform Support](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)](https://flutter.dev)
[![Repository](https://img.shields.io/badge/Repository-GitHub-green.svg?logo=github)](https://github.com/Sesss123/hiden_gem-app.git)

A next-generation, premium mobile application designed for discovering, planning, and experiencing the hidden historical landmarks, cultural spots, and scenic locations across Sri Lanka. Built with premium modern aesthetics, smooth micro-animations, comprehensive localization, and a military-grade security core.

---

## 🌟 Core Features

### 🗺️ Intelligent Trip Planner & Map Routes
- **Interactive Trip Wizard:** Multi-step customizable trip forms allowing city autocomplete and manual free-text validation.
- **Dynamic Route Optimization:** Live coordinate mapping using custom Sri Lankan city latitude and longitude tables.
- **Offline Maps & Navigation:** Local trip plan saving featuring robust network status checking and offline-ready warning configurations.

### 🕶️ Augmented Reality (AR) & Audio Narration (Phase 9)
- **3D Landmark Scanner:** Render detailed 3D historical structures using Google ARCore directly overlaying the camera feed.
- **360° Panorama Viewer:** Interactive immersive layouts for experiencing destinations virtually before physical visits.
- **Audio Guide Streamer:** Direct streaming narration for cultural markers and historical guides using the `just_audio` system.
- **AR Hardware Gating:** Dynamic fallback screens and auto-detection upgrades for older devices lacking ARCore drivers.

### 🛡️ Zenith Security Nexus (Anti-Tampering & Trust)
- **Integrity Shield Engine:** Client-side runtime scanner checking for device root/jailbreak status, emulator environments, attached debuggers, and application signature validity.
- **Cryptographic Secure Communication:** SSL pinning enforcement, request timestamp validation, and SHA-256 HMAC payload signatures protecting the back-end integrity.
- **Location Spoof Protection:** Advanced GPS detection scanning against simulated providers and fake coordinates.
- **Secure Forensic Pipeline:** Instant quarantine routing, logging security violations to Firestore `security_events`, and hardware-level throttling.
- **AES Storage Encryption:** Strong local storage encryption mapping cache inputs using customized AES encryption engines.

### 🍽️ Cultural & Gamification Modules
- **Savor Lanka:** A vibrant culinary guide showcasing authentic Sri Lankan traditional recipes, historical background, and clay-pot interactive instructions.
- **Heritage Passport:** Travel gamification allowing users to scan regional markers, unlock virtual stamps, and earn custom-designed achievement badges.
- **Ancestral Portal:** Exploration tool facilitating lineage records retrieval and heritage searches.

### 🤝 Registered Guide Marketplace
- **Smart Match Engine:** Intelligent recommendation system connecting tourists with certified regional tour guides using specific filters (category, language, region, vehicle availability).
- **Guide Dashboard:** Tour session control (QR check-in, live phase tracking, meeting-point broadcasts), listing management, vehicle details, and safety tools, all in one tabbed dashboard.
- **Booking Flow:** Tourists send a booking request from a guide's public profile (optionally against a custom tour package); guides accept/decline from their inbox, with both sides notified through Firestore-backed in-app notifications and a **My Bookings** status screen for tourists.
- **Subscription Tiers (Free / Pro / Elite):** Real entitlement-gated features for guides — Featured Listings, Priority SOS routing, Advanced Analytics, Priority Leads, a Verified & Insured badge, Custom Tour Packages (Pro+), and Team Management / Operator Dashboard / White-label Branding (Elite). Free-tier guides also get a lightweight Client CRM and native device Calendar Sync.

---

## 🧩 Backend Services

The app is backed by two services, split by what each is good at:

- **Firebase / Firestore:** Primary data store and realtime layer — guide listings, bookings, subscriptions, chat/notifications, and Firestore Security Rules for access control. A small set of Cloud Functions (`functions/`) handle privileged operations (entitlement verification, RevenueCat webhooks, forensic signal scoring) that can't be trusted to the client.
- **Laravel Backend (`laravel-backend/`):** Admin panel (guide application review, marketplace listing oversight) and server-side operations that Firestore Security Rules can't safely allow a client to perform directly — e.g. incrementing a guide's booking/profile-view counters, or checking another guide's monthly booking quota before a tourist submits a request. Talks to Firestore via a service-account-backed REST wrapper (`FirestoreService`), independent of the Cloud Functions runtime.

---

## 🏗️ Architecture & Directory Layout

The application adheres to clean architecture guidelines to separate logic, presentation, and data management:

```
lib/
├── core/                         # Shared core features and global utils
│   ├── analytics/                # Logging and metrics controllers
│   ├── config/                   # Dynamic configs, API endpoints, App Check setup
│   ├── localization/             # App translations (English, Sinhala, Tamil, Japanese, Russian, Korean)
│   ├── models/                   # Immutably designed base schema models (TripPlan, etc.)
│   ├── network/                  # SSL pinned client with HMAC signatures
│   ├── notifications/            # Push messaging and FCM alerts
│   ├── providers/                # Theme, connection, and auth state providers
│   ├── security/                 # Zenith Stress Defense check suites
│   ├── services/                 # Firebase services, local Hive databases, TTS Engine
│   ├── theme/                    # Breeze (Light) & Abyss (Dark) glassmorphic themes
│   └── utils/                    # Common formatting and device size utilities
│
├── data/                         # Local & Remote data layer interfaces
│   ├── datasources/              # Hive caching and Firestore streams
│   └── repositories/             # Discovery and booking implementations
│
├── features/                     # Highly specialized modules
│   └── ar_video/                 # Immersive spatial video panoramas
│
├── presentation/                 # Presentation / User Interface layer
│   ├── controllers/              # UI-specific state controllers
│   ├── screens/                  # Application screens (40+ customized user interfaces)
│   └── widgets/                  # Reusable Oracle UI visual elements & SliverAppBars
│
├── firebase_options.dart         # Generated Firebase configuration configurations
└── main.dart                     # App setup, provider initialization, and splash loading entry

functions/                        # Firebase Cloud Functions (privileged operations)
laravel-backend/                  # Admin panel + server-side Firestore operations (PHP/Laravel)
firestore.rules                   # Firestore Security Rules
firestore.indexes.json            # Firestore composite index definitions
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK:** `^3.3.0`
- **Dart SDK:** `^3.0.0`
- **Android Studio / Xcode:** For compilation and run environment
- **ARCore / ARKit Support:** Required to trigger the AR Viewer screens

### Local Installation & Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Sesss123/hiden_gem-app.git
   cd hiden_gem-app
   ```

2. **Retrieve Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Riverpod & Hive Adapters:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Verify Application Static Correctness:**
   ```bash
   flutter analyze
   ```

5. **Run the Application locally:**
   ```bash
   flutter run
   ```

### Laravel Backend Setup

Guide-side features (admin panel, booking quota checks, marketplace counters) require the Laravel backend running alongside the app:

```bash
cd laravel-backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

Point the Flutter app at it via `--dart-define=LARAVEL_BACKEND_URL=http://localhost:8000/api/v1` (adjust host/port to match your `artisan serve` or Herd setup).

---

## 📦 Production Builds & Obfuscation

**Always build releases with the committed build script — never a raw
`flutter build`.** The script guarantees `--obfuscate --split-debug-info` (so a
release can never ship un-obfuscated by accident) and injects all
`--dart-define` secrets from `dart_defines.json` instead of hardcoding them.

```powershell
# Windows (PowerShell) — appbundle by default
./scripts/build_release.ps1                 # -> .aab
./scripts/build_release.ps1 -Target apk     # -> .apk
```
```bash
# macOS / Linux / CI
./scripts/build_release.sh                  # -> .aab
./scripts/build_release.sh apk              # -> .apk
./scripts/build_release.sh ipa              # -> iOS
```

First-time setup: `cp dart_defines.example.json dart_defines.json` and fill in
the values (this file is gitignored). Obfuscation symbols are written to
`symbols/<target>/` — **archive them**; you need them to de-obfuscate
Crashlytics stack traces.

> [!NOTE]
> Secrets in `dart_defines.json` are compiled into the binary and ARE
> extractable from the APK — they raise attacker cost, they are not true
> secrets. See `HARDENING.md` for what actually protects the app server-side.

### Web Release Build
Minification is handled automatically by the compiler:
```bash
flutter build web
```

---

## 📄 License & Deployment
- **Repository Remote:** `https://github.com/Sesss123/hiden_gem-app.git`
- **Publish Settings:** Marked `publish_to: 'none'` in `pubspec.yaml` to prevent accidental public packaging releases.
