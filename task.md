
## Active Milestone: Resolve 10-Bug Audit Report
- [x] Fix double-call to `performInitialization()` in `main.dart`
- [x] Fix kill-switch triggered `runApp()` double call in `main.dart`
- [x] Fix `pubspec.yaml` iOS launcher icon typo
- [x] Complete missing basic translations for KO/JA/RU/TA
- [x] Add `Platform.isAndroid` check to ARCore usages to prevent iOS crash
- [x] Decouple LLM configuration in `AppConfig` and validate in production
- [x] Upgrade hardcoded model references from `gemini-1.5-flash` to use `AppConfig.llmModelName`

## Active Milestone: Complete remaining dashboard UI & limit issues
- [x] Decouple offline download limits from saved_plans key (`usage_limiter_service.dart`)
- [x] Create and embed UsageMeterWidget in Home and Profile screens (`usage_meter_widget.dart`, `home_screen.dart`, `profile_screen.dart`)
- [x] Implement SoftUpgradeNudgeCard inline warning in step 1 trip creator (`soft_upgrade_nudge_card.dart`, `trip_form_screen.dart`)
- [x] Resolve subscription routing confusion between tourist PremiumHubScreen and guide SubscriptionScreen (`profile_screen.dart`, `limit_reached_dialog.dart`)
- [x] Turn OnboardingScreen into a 5-step Interactive Onboarding Tour (`onboarding_screen.dart`)

## Active Milestone: Resolve AR Flow Gaps (Surface Detection & Rewarded Ad)
- [x] Harden surface detection instructions and tap feedback (`ar_video_screen.dart`)
- [x] Integrate rewarded ad path in upgrade dialog and fallback view (`ar_upgrade_dialog.dart`, `place_details_screen.dart`, `ar_viewer_screen.dart`, `ar_fallback_screen.dart`)

## Active Milestone: Fix 6 Issues in AR Content Preview Screen
- [x] Implement ARVideoContent model enhancements (`ar_video_content.dart`)
- [x] Add initialLang property to ARVideoScreen (`ar_video_screen.dart`)
- [x] Redesign Hero Banner with location images & gradient overlays (`ar_content_preview_screen.dart`)
- [x] Show description, duration, and guide information (`ar_content_preview_screen.dart`)
- [x] Harden loading state with spinner, timeout, and retry button (`ar_content_preview_screen.dart`)
- [x] Add Share, Bookmark, and Add-to-Itinerary actions row (`ar_content_preview_screen.dart`)
- [x] Integrate language selector toggle (`ar_content_preview_screen.dart`)
- [x] Enhance timeline cards (interactive details bottom sheet & bilingual texts) (`ar_content_preview_screen.dart`)

## Active Milestone: Project Documentation & Enhancement
- [x] Add a comprehensive, premium project README (`README.md`)

## Active Milestone: Fix Remaining Static Analysis Issues
- [x] Clean up unused imports across data, presentation, and core layers
- [x] Remove dead code, unused private fields/methods, and unnecessary casts
- [x] Fix AppCheck type errors (`AndroidAppCheckProvider` / `AppleAppCheckProvider`) and UI deprecations (`activeThumbColor`, `zIndexInt`, `initialValue`)
- [x] Fix Share / shareXFiles deprecation warnings by updating to SharePlus.instance.share(ShareParams(...))
- [x] Fix Geolocator deprecations (`locationSettings`) and resolve BuildContext async gap warnings (`use_build_context_synchronously`)
- [x] Fix all remaining `withOpacity` deprecations across the codebase by updating to `withValues(alpha: ...)`

## Active Milestone: Complete 47-Bug Audit Fixes

- [x] **Critical Fixes (11 bugs)**
  - [x] C-01: Origin coordinates lookup table mapping (`loading_plan_screen.dart`)
  - [x] C-02: PDF/Voice premium lock redirect index fix (`results_screen.dart`)
  - [x] C-03: Pushing Operator Dashboard admin/role guard checks (`profile_screen.dart` & `operator_dashboard_screen.dart`)
  - [x] C-04: Autocomplete free-text entry validation (`trip_form_screen.dart`)
  - [x] C-05: Save budget tracker expenses when plan is unsaved (`budget_tracker_screen.dart`)
  - [x] C-06: TripCacheService `clearAll()` only clears transient logs (`trip_cache_service.dart`)
  - [x] C-07: Contextual scanner details simulation (`scanner_screen.dart`)
  - [x] C-08: Bind admin user listing to UserRepository streams (`operator_dashboard_screen.dart`)
  - [x] C-09: Add video player exceptions try-catches in splash screen (`splash_screen.dart` / `ar_fallback_screen.dart`)
  - [x] C-10: Dynamic configuration URL endpoint load fallback (`app_config.dart`)
  - [x] C-11: Google sign-in exception detail extraction (`auth_service.dart`)
- [x] **Workflow & UX Fixes (18 bugs)**
  - [x] W-01: Add city autocomplete validation on form Step 1 (`trip_form_screen.dart`)
  - [x] W-02: Toggle bookmark state save and unsave logic (`results_screen.dart`)
  - [x] W-03: Combine emergency contacts into single SMS intent (`emergency_kit_screen.dart`)
  - [x] W-04: Validate settings check on onboarding completion (`onboarding_screen.dart`)
  - [x] W-05: Ad loader warnings and checks (`monetization_service.dart`)
  - [x] W-06: Delay interstitial preloading calls on ad dismissal (`monetization_service.dart`)
  - [x] W-07: Remove fake mock delay in event calendar (`event_calendar_screen.dart`)
  - [x] W-08: Voice service error reset callback handlers (`voice_service.dart`)
  - [x] W-09: Offline map warning snackbar action button (`map_route_screen.dart`)
  - [x] W-10: Reset search filter matching values in discovery (`discovery_screen.dart`)
  - [x] W-11: Correct waterfall category search typo (`discovery_screen.dart`)
  - [x] W-12: Pass planId parameters from Results screen triggers (`results_screen.dart`)
  - [x] W-13: Camera resume lifecycle restart checks (`scanner_screen.dart`)
  - [x] W-14: Consolidation of splash screen provider indicators (`main.dart`)
  - [x] W-15: Integrate robust network checks (`map_route_screen.dart`)
  - [x] W-16: Startup state initialization fallback overrides (`main.dart`)
  - [x] W-17: File verification checks before profile image load (`profile_screen.dart`)
  - [x] W-18: Login screen exception detail text mapper (`login_screen.dart`)
- [x] **UI & Dark Mode Fixes (12 bugs)**
  - [x] U-01: Results screen theme-aware background (`results_screen.dart`)
  - [x] U-02: Loading plan screen theme-aware text colors (`loading_plan_screen.dart`)
  - [x] U-03: Theme-aware splash screen loaders (`splash_screen.dart`)
  - [x] U-04: Adaptation of budget tracker colors for light mode (`budget_tracker_screen.dart`)
  - [x] U-05: Verified badge accessibility scale (`results_screen.dart`)
  - [x] U-06: Dynamic place card illustration image assets (`discovery_screen.dart`)
  - [x] U-07: Dynamic place details hero image mapping (`place_details_screen.dart`)
  - [x] U-08: Cache background banner image loading (`home_screen.dart`)
  - [x] U-09: Dynamic BottomNav height scaling check (`home_screen.dart`)
  - [x] U-10: SliverAppBar text legibility drop shadows (`results_screen.dart`)
  - [x] U-11: DropdownButtonFormField deprecated fields (`budget_tracker_screen.dart`)
  - [x] U-13: Dynamic scroller gems mapping (`home_screen.dart`)
- [x] **Code Quality & Minor Fixes (6 bugs)**
  - [x] Q-01: API key production environment check (`app_config.dart`)
  - [x] Q-02: Consolidate duplicated theme mode providers
  - [x] Q-03: Enforce immutability on `TripPlan` properties (`trip_plan_model.dart`)
  - [x] Q-04: Implement localization district defaults (`discovery_screen.dart`)
  - [x] Q-05: Query device locale support before TTS assistant play (`voice_service.dart`)
  - [x] Q-06: Validate data fields in parsing schema overrides (`trip_plan_model.dart`)


# Completed
- [x] **Fix Remaining Static Analysis Issues**: Resolved unused imports, dead code, unused private fields/methods, and unnecessary casts across `incident_detail_screen.dart`, `language_selection_screen.dart`, `map_explorer_screen.dart`, `operator_dashboard_screen.dart`, `profile_screen.dart`, `results_screen.dart`, `savor_lanka_screen.dart`, and `smart_match_screen.dart`. (Completed on 2026-06-27)
- [x] **Fix AppConfig tripMeApiKey Compiler Errors**: Added a backwards-compatible `tripMeApiKey` getter inside `AppConfig` to solve undefined getter compiler issues. (Completed on 2026-06-27)
- [x] **Complete remaining dashboard UI & limit issues**: Decoupled offline downloads from saved_plans, built and embedded `UsageMeterWidget` in Home and Profile, created and embedded `SoftUpgradeNudgeCard` in the trip creator step 1, resolved routing confusion for PremiumHub and Subscription screens based on user roles, and updated `OnboardingScreen` into a 5-step interactive tour (Discovery, Planner, AR, Guides, Safety). (Completed on 2026-06-27)
- [x] **Resolve AR Flow Gaps (Surface Detection & Rewarded Ad)**: Hardened surface detection flow by adding an environment scanning step, detailed instructions, and plane hit validation. Surfaced the rewarded ad unlock path directly in `ARUpgradeDialog` (invoked in place details and AR viewer screens) and `ARFallbackScreen` to prevent dead ends for free tier users. (Completed on 2026-06-27)
- [x] **Fix 6 Issues in AR Content Preview Screen**: Hardened and enhanced the preview screen by adding a premium hero banner, descriptions/durations, loading timeouts and retry widgets, share/bookmark/itinerary action flows, language switching, and interactive timeline sync cards. (Completed on 2026-06-27)
- [x] **Add a comprehensive, premium project README**: Created the root `README.md` containing features, project architecture layout, setup prerequisites, build instructions, and security details. (Completed on 2026-06-27)
- [x] **Initialized Task Tracking File**: Created and formatted the main `task.md` in the project root. (Completed on 2026-06-19)

### Flutter Analyze Fixes (Audit)
- [x] **Core / Config Layer**
  - [x] `analytics_service.dart` — string interpolation fix
  - [x] `app_check_config.dart` — deprecated provider params
  - [x] `forensic_payload.dart` — unused import
  - [x] `device_trust_graph.dart` — unused field + variable
  - [x] `emergency_control_service.dart` — prefer_is_empty
  - [x] `integrity_shield.dart` — unused import
  - [x] `oracle_guardian.dart` — unused field _iv
  - [x] `secure_entitlements.dart` — unused field + null comparison
  - [x] `security_alert_service.dart` — unused import + field
  - [x] `session_quarantine.dart` — unused field + catchError return
  - [x] `voice_recipe_service.dart` — unused import
  - [x] `oracle_ui_system.dart` — unused local variable
  - [x] `theme_provider.dart` — unreachable switch default
  - [x] `image_utils.dart` — unused import
- [x] **Data Layer**
  - [x] `discovery_local_datasource.dart` — duplicate import
  - [x] `user_profile.dart` — dead null-aware expression
  - [x] `analytics_repository.dart` — unused import + curly braces
  - [x] `booking_repository.dart` — unnecessary cast
  - [x] `guide_profile.dart` — unused import
  - [x] `session_presence.dart` — unused import
  - [x] `premium_service.dart` — deprecated purchasePackage
  - [x] `firebase_storage_service.dart` — avoid_print
- [x] **Main App**
  - [x] `main.dart` — duplicate import + unused import
- [x] **Presentation — Screens & Widgets**
  - [x] `screenshot_service.dart` — deprecated Share
  - [x] `ar_viewer_screen.dart` — deprecated Share (4x)
  - [x] `budget_tracker_screen.dart` — deprecated value param
  - [x] `discovery_screen.dart` — activeColor → activeThumbColor
  - [x] `emergency_kit_screen.dart` — dead null-aware expression
  - [x] `event_calendar_screen.dart` — unnecessary import + deprecated Share
  - [x] `family_share_screen.dart` — unused import + activeColor
  - [x] `guide_broadcast_screen.dart` — withOpacity (4x)
  - [x] `guide_dashboard_screen.dart` — multiple issues
  - [x] `guide_enrollment_screen.dart` — unused import + withOpacity
  - [x] `guide_marketplace_screen.dart` — unused field + mounted check + activeColor
  - [x] `home_screen.dart` — unused imports + unused field
  - [x] `incident_center_screen.dart` — unused import
  - [x] `incident_detail_screen.dart` — null comparison issues
  - [x] `language_selection_screen.dart` — unused variable
  - [x] `map_explorer_screen.dart` — unused import + field + zIndex
  - [x] `operator_dashboard_screen.dart` — unused import
  - [x] `place_details_screen.dart` — BuildContext async gaps (3x)
  - [x] `profile_screen.dart` — unused import + cast + mounted checks
  - [x] `results_screen.dart` — unused private declarations
  - [x] `review_submission_screen.dart` — final field
  - [x] `savor_lanka_screen.dart` — multiple issues
  - [x] `smart_match_screen.dart` — unused imports (4x)
  - [x] `terms_screen.dart` — unused import
  - [x] `tourist_companion_hub.dart` — multiple issues
  - [x] `trip_form_screen.dart` — mounted check
  - [x] `itinerary_timeline_widget.dart` — deprecated onReorder
  - [x] `marketplace_search_bar.dart` — withOpacity (8x)
  - [x] `qr_scanner_screen.dart` — withOpacity (2x)

### 47-Bug Audit Fixes (Critical & Initial Workflows)
- [x] **C-01: Origin coordinates lookup table mapping**: Mapped Sri Lankan cities to lat/lng coordinates in `loading_plan_screen.dart`. (Completed on 2026-06-19)
- [x] **C-02: PDF/Voice premium lock redirect index**: Fixed Voice premium lock tab redirect target index to 3 in `results_screen.dart`. (Completed on 2026-06-19)
- [x] **C-03: Operator Dashboard admin/role guard checks**: Added role and guide status verification for the Operator Dashboard in `profile_screen.dart` and `operator_dashboard_screen.dart`. (Completed on 2026-06-19)
- [x] **C-04 & W-01: Autocomplete free-text entry & validation**: Integrated manual typing state mapping and Sri Lankan city list validation in `trip_form_screen.dart` for Step 1. (Completed on 2026-06-19)
- [x] **C-05: Save budget tracker expenses when plan is unsaved**: Added cache keys and transient Hive box persistence in `budget_tracker_screen.dart`. (Completed on 2026-06-19)
- [x] **C-06: TripCacheService `clearAll()` safety check**: Modified `clearAll` to preserve user-bookmarked plans in `trip_cache_service.dart`. (Completed on 2026-06-19)
- [x] **C-07: Contextual scanner details simulation**: Added randomized historical landmark data pool in `scanner_screen.dart`. (Completed on 2026-06-19)
- [x] **C-08: Bind admin user listing to UserRepository streams**: Linked administrative user listing widget to live Firestore streams in `operator_dashboard_screen.dart`. (Completed on 2026-06-19)
- [x] **C-09: Add video player exceptions try-catches**: Hardened video player loading and errors in `ar_fallback_screen.dart` to prevent network exceptions from causing crashes. (Completed on 2026-06-19)
- [x] **C-10: Dynamic configuration URL endpoint load fallback**: Replaced hardcoded LAN IPs with dynamic environment checks in `app_config.dart`. (Completed on 2026-06-19)
- [x] **C-11: Google sign-in exception detail extraction**: Propagated and handled Google Sign-in exceptions to display detailed SnackBar alerts in `auth_service.dart` and `login_screen.dart`. (Completed on 2026-06-19)
- [x] **Q-01: API key production environment check**: Added static validate checks throwing alerts on empty keys in release builds in `app_config.dart`. (Completed on 2026-06-19)
- [x] **W-13: Camera resume lifecycle restart checks**: Set camera controller reference to null on inactivation and re-initialized on app resume in `scanner_screen.dart`. (Completed on 2026-06-19)
- [x] **W-02: Toggle bookmark state**: Added saved plan removal/unsave logic on tapping the bookmark button in `results_screen.dart`. (Completed on 2026-06-19)
- [x] **W-09: Offline map warning SnackBar action**: Added "SAVE TRIP" action to the offline map warning SnackBar in `map_route_screen.dart`. (Completed on 2026-06-19)
- [x] **U-02: Loading plan screen theme-aware text colors**: Made loading status text dynamic based on brightness in `loading_plan_screen.dart`. (Completed on 2026-06-19)
- [x] **U-05: Verified badge accessibility scale**: Scaled verified sub-badges font sizes to 9 minimum in `guide_reviews_screen.dart` and `kinetic_timeline_view.dart`. (Completed on 2026-06-19)
- [x] **U-09: Dynamic BottomNav height scaling check**: Dynamically scaled BottomNav height based on system font scaling factor in `home_screen.dart`. (Completed on 2026-06-19)
- [x] **U-10: SliverAppBar text legibility drop shadows**: Enhanced title/subtitle readability and drop shadows in `results_screen.dart`. (Completed on 2026-06-19)
- [x] **U-08: Cache background banner image loading**: Pre-cached all home page background banner asset images in memory to prevent reload flickering in `home_screen.dart`. (Completed on 2026-06-19)
- [x] **U-12: Dynamic scroller gems mapping**: Bound local offline gems scroller to live `DiscoveryPlace` assets parsed dynamically via `DiscoveryRepository` in `home_screen.dart`. (Completed on 2026-06-19)

### Core UI & Navigation System
- [x] **Theme Shell Engine**: Created Breeze (light) and Abyss (dark) theme styles in `app_theme.dart`. (Completed on 2026-06-19)
- [x] **Oracle UI System**: Implemented dynamic glassmorphic containers, neon effects, and custom layouts in `oracle_ui_system.dart`. (Completed on 2026-06-19)
- [x] **Splash & Onboarding Screens**: Created `splash_screen.dart` and `onboarding_screen.dart` with custom entry transitions. (Completed on 2026-06-19)
- [x] **Language & Localization Config**: Integrated translation services supporting English, Sinhala, Tamil, Japanese, Russian, and Korean. (Completed on 2026-06-19)
- [x] **Home Dashboard Screen**: Built main user hub featuring categories, recent itineraries, CTA buttons, and bottom nav navigation. (Completed on 2026-06-19)
- [x] **Terms Agreement Screen**: Integrated a compliance screen to verify user acceptance before using the application. (Completed on 2026-06-19)

### Zenith Stress Defense (Security & Anti-Tampering)
- [x] **Zenith Security Nexus (5 Keys)**: Configured client-side verification fragmenting access across local flags, server proofs, integrity checks, quarantine status, and cryptographic expiry signatures. (Completed on 2026-06-19)
- [x] **Integrity Shield Engine**: Programmed multi-signal local checks detecting root/jailbreak, emulator environments, attached debuggers, and app signature mismatches. (Completed on 2026-06-19)
- [x] **SSL Pinning & HMAC Signatures**: Built a hardened network client executing certificate pinning, request-timestamp validation, and SHA-256 HMAC payload signatures. (Completed on 2026-06-19)
- [x] **Emergency Controls (Panic Room)**: Coded Remote Config switches for immediate global kill-switch, synthetic lag throttling, and feature-specific gating. (Completed on 2026-06-19)
- [x] **Forensic Reporting & Quarantine**: Built a secure incident collection pipeline sending immutable data logs to Firestore `security_events` and throttling suspicious accounts. (Completed on 2026-06-19)
- [x] **Location Spoof Detection**: Programmed real-time GPS check tools mapping against mock provider tools. (Completed on 2026-06-19)
- [x] **Encryption Service**: Implemented AES cryptographic utilities (`encryption_util.dart`) for local app cache. (Completed on 2026-06-19)

### AR (Augmented Reality) & Audio guides (Phase 9)
- [x] **AR Viewer Screen**: Built an interactive 3D local artifact previewer using Google ARCore plugin. (Completed on 2026-06-19)
- [x] **AR Video Screen**: Coded immersive spatial video views and panorama 360 degree layouts. (Completed on 2026-06-19)
- [x] **AR Upgrade Dialog & Fallbacks**: Designed fallback views for devices lacking AR hardware capabilities. (Completed on 2026-06-19)
- [x] **Audio Guide Streamer**: Configured speech-to-text narration streaming for places using the `just_audio` package. (Completed on 2026-06-19)

### Cultural & Functional Travel Modules
- [x] **Savor Lanka Screen**: Implemented local culinary guide screens focusing on traditional recipes, clay-pot cooking, and sweets preparation. (Completed on 2026-06-19)
- [x] **Guide Marketplace**: Created screens and models for local registered tour guides, review submissions, and guide profile cards. (Completed on 2026-06-19)
- [x] **Smart Match Engine**: Programmed matching rules linking tourists to regional guides based on preferences. (Completed on 2026-06-19)
- [x] **Kinetic Pulse Hub**: Designed current travel alerts and local safety warning dashboards. (Completed on 2026-06-19)
- [x] **Budget Tracker & Concierge**: Built interactive financial screens tracking trip expenses and AI-driven currency budgets. (Completed on 2026-06-19)
- [x] **Ancestral Portal Screen**: Integrated heritage discovery searches mapping ancient Sri Lankan lineage records. (Completed on 2026-06-19)
- [x] **Heritage Passport Screen**: Programmed a travel gamification model unlocking badges and virtual passport stamps at national sites. (Completed on 2026-06-19)
- [x] **Trip Planner & Map Routes**: Created interactive map routing and trip customization forms. (Completed on 2026-06-19)
- [x] **Git Remote Migration Guidance**: Generated instructions to remove old Git history and push the project to the new repository `https://github.com/Sesss123/hiden_gem-app.git`. (Completed on 2026-06-19)
- [x] **Q-02: Consolidate duplicated theme mode providers**: Consolidated all theme-related state handling into a single `themeModeProvider` backed by `UserPreferenceService`. (Completed on 2026-06-19)
- [x] **Q-03: Enforce immutability on TripPlan properties**: Made `offlineMapPath` final and implemented the `copyWith` pattern in `TripPlan` and `MapRouteScreen`. (Completed on 2026-06-19)
- [x] **Q-04: Implement localization district defaults**: Refactored `DiscoveryScreen` category filters to dynamically resolve district strings using place/city name lookup mapping when empty. (Completed on 2026-06-19)
- [x] **Q-06: Validate data fields in parsing schema overrides**: Added strict format checks and validations to `TripPlan.fromJson` constructor to detect and reject malformed JSON. (Completed on 2026-06-19)

