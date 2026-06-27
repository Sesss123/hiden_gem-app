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
- **Smart Match Engine:** Intelligent recommendation system connecting tourists with certified regional tour guides using specific filters.
- **Guide Dashboard:** Administrative panels for local guides to handle live bookings, broadcast statuses, and publish localized reviews.

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

---

## 📦 Production Builds & Obfuscation

To protect the application's underlying code against reverse engineering and keep asset payloads minimal, compile using the production build commands below:

### Android APK Build
```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

### iOS Build
```bash
flutter build ios --obfuscate --split-debug-info=build/ios/outputs/symbols
```

### Web Release Build
Minification is automatically handled by the compiler compiler optimization scripts:
```bash
flutter build web
```

---

## 📄 License & Deployment
- **Repository Remote:** `https://github.com/Sesss123/hiden_gem-app.git`
- **Publish Settings:** Marked `publish_to: 'none'` in `pubspec.yaml` to prevent accidental public packaging releases.
