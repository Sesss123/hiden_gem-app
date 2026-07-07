import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/services/security_orchestrator.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart'; 
import 'data/datasources/trip_cache_service.dart';
import 'data/datasources/user_preference_service.dart';
import 'data/datasources/monetization_service.dart';
import 'data/datasources/voice_service.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/network/secure_network.dart';
import 'core/services/delta_sync_service.dart';
import 'core/utils/secure_logger.dart';
import 'core/utils/encryption_util.dart';
import 'package:safe_device/safe_device.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/booking_inbox_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/screens/terms_screen.dart';
import 'presentation/widgets/graceful_error_widget.dart';
import 'firebase_options.dart';
import 'core/config/remote_config_service.dart';
import 'core/providers/screenshot_provider.dart';
import 'core/config/app_config.dart';
import 'package:screenshot/screenshot.dart';
import 'core/utils/screenshot_service.dart';
import 'presentation/widgets/golden_tracer_indicator.dart';
import 'core/services/update_service.dart';
import 'presentation/screens/update_screen.dart';
import 'core/config/app_check_config.dart';
import 'core/services/zenith_security_facade.dart';
import 'core/services/emergency_control_service.dart';
import 'core/services/monsoon_broadcast_service.dart';
import 'core/services/consent_service.dart';
import 'package:freerasp/freerasp.dart';
import 'presentation/widgets/app_lock_wrapper.dart';

class InitializationResult {
  final bool hiveSuccess;
  final bool firebaseSuccess;
  final bool isCompromised;
  final bool isKillSwitchActive;
  final String? maintenanceMessage;
  final String? error;

  InitializationResult({
    required this.hiveSuccess,
    required this.firebaseSuccess,
    this.isCompromised = false,
    this.isKillSwitchActive = false,
    this.maintenanceMessage,
    this.error,
  });

  bool get canProceed => hiveSuccess && (kIsWeb || !isCompromised) && !isKillSwitchActive;
}

// SecureNetwork from core/network/secure_network.dart is used instead.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Global Error Handling
  FlutterError.onError = (errorDetails) {
    // 1. Report to Crashlytics (Mobile Native only)
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      }
    } catch (e) {
      SecureLogger.error("Suppressing Crashlytics error during reporting: $e");
    }
    
    // 2. Log to Analytics (Safe for Web/Mobile)
    try {
      AnalyticsService().logEvent('runtime_error', parameters: {
        'exception': errorDetails.exceptionAsString(),
        'stack': errorDetails.stack.toString(),
      });
    } catch (e) {
      SecureLogger.warning("Failed to log runtime_error to AnalyticsService: $e");
    }

    // 3. Keep Default Behavior (Show Red Screen/Overflow Indicator)
    FlutterError.presentError(errorDetails);
  };
  
  // BUG-065: PlatformDispatcher.instance.onError is bound here to catch ALL
  // uncaught platform exceptions that bypass FlutterError.onError (e.g., async
  // exceptions in isolates and platform channels). This prevents them from
  // silently crashing the app without being logged or reported.
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (e) {
      SecureLogger.error("Suppressing Crashlytics error in dispatcher: $e");
    }
    return true;
  };
  
  SecureLogger.info("Main Entry: Initializing Firebase and core storage concurrently...");
  
  // 1. Concurrently initialize Firebase and Essential Local Storage (Hive)
  // This satisfies the user requirement to initialize Firebase before runApp (preventing [core/no-app] errors and Firestore GeoHash fetch failures)
  // while running tasks in parallel via Future.wait to eliminate main-thread jank (Skipped 20 frames... warning).
  try {
    FirebaseOptions? options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } catch (e) {
      SecureLogger.error("Firebase config not available for this platform: $e");
    }

    await Future.wait([
      if (options != null && Firebase.apps.isEmpty)
        Firebase.initializeApp(options: options).then((_) {
          // Enable Firestore offline persistence immediately upon initialization
          FirebaseFirestore.instance.settings = Settings(
            persistenceEnabled: true,
            cacheSizeBytes: kIsWeb ? 20 * 1024 * 1024 : Settings.CACHE_SIZE_UNLIMITED,
          );
        }),
      TripCacheService.init(),
      UserPreferenceService.init(),
    ]);
    
    await UserPreferenceService.ensureProfileLoaded();
    SecureLogger.info("Core storage and Firebase ready.");
  } catch (e) {
    SecureLogger.error("CRITICAL Startup Init Error: $e");
  }

  // Apply Strict HTTPS Security and SSL Pinning configuration globally
  if (!kIsWeb) {
    HttpOverrides.global = SecureNetworkOverrides();

    // Initialize freeRASP for Runtime App Self-Protection
    try {
      final config = TalsecConfig(
        androidConfig: AndroidConfig(
          packageName: 'com.hidden.gems.hidden_gems_sl',
          signingCertHashes: ['PLACEHOLDER_HASH'],
          supportedAlternativeStores: [],
        ),
        iosConfig: IOSConfig(
          bundleIds: ['com.hidden.gems.hiddenGemsSl'],
          teamId: 'PLACEHOLDER_TEAM_ID',
        ),
        watcherMail: 'support@hiddengemssl.com',
        isProd: kReleaseMode,
      );
      final callback = ThreatCallback(
        onAppIntegrity: () => SystemNavigator.pop(),
        onObfuscationIssues: () => SystemNavigator.pop(),
        onDebug: () => SystemNavigator.pop(),
        onDeviceBinding: () => SystemNavigator.pop(),
        onDeviceID: () => SystemNavigator.pop(),
        onHooks: () => SystemNavigator.pop(),
        onPrivilegeEscalation: () => SystemNavigator.pop(), // Force close on root/jailbreak
        onSecureHardwareNotAvailable: () => {},
        onSimulator: () {
          if (kReleaseMode) SystemNavigator.pop();
        },
        onUnofficialStore: () => {},
      );
      Talsec.instance.start(config);
      Talsec.instance.attachListener(callback);
      SecureLogger.info("freeRASP Security Shield Activated");
    } catch(e) {
      SecureLogger.error("freeRASP Initialization Error: $e");
    }
  }

  // FLAG_SECURE is now handled directly in android/app/src/main/kotlin/com/hidden/gems/hidden_gems_sl/MainActivity.kt
  // for better compatibility and build reliability.

  // Initialization is kicked off by appInitializationProvider which is observed by HiddenGemsApp.

  runApp(
    const ProviderScope(
      child: HiddenGemsApp(),
    ),
  );
}

class AppInitState {
  final InitializationResult result;
  final UpdateType updateType;

  AppInitState({required this.result, required this.updateType});
}

// Global initialization future provider to replace the logic passed into HiddenGemsApp
final appInitializationProvider = FutureProvider<AppInitState>((ref) async {
  final result = await performInitialization().timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      SecureLogger.warning("Initialization timed out. Proceeding in fallback mode.");
      return InitializationResult(hiveSuccess: true, firebaseSuccess: false);
    },
  );

  // BUG-131: Invalidate locale and theme providers once initialization completes
  // to prevent settings from resetting during early app boot / hot restart.
  ref.invalidate(localeProvider);
  ref.invalidate(themeModeProvider);

  UpdateType updateType = UpdateType.none;
  if (result.firebaseSuccess) {
    await initializeOtherServices();
    try {
      updateType = await UpdateService().checkUpdate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => UpdateType.none,
      );
    } catch (e) {
      SecureLogger.warning("Update check failed or timed out during init: $e");
    }
  }
  return AppInitState(result: result, updateType: updateType);
});

Future<InitializationResult> performInitialization() async {
  bool firebaseStatus = false;
  bool isCompromised = false;
  bool storageStatus = TripCacheService.isInitialized;
  String? errorMessage;

  // BUG-125: Outer catch-all — any unexpected startup anomaly returns a
  // degraded result instead of propagating and halting the application.
  try {

  try {
    AppConfig.validate();
  } catch (e) {
    SecureLogger.error("Validation error: $e");
    return InitializationResult(
      hiveSuccess: storageStatus,
      firebaseSuccess: false,
      error: e.toString(),
    );
  }

  SecureLogger.info("Background initialization started. Web mode: $kIsWeb");

  try {
    // Initialize Encryption System early
    await EncryptionUtil.init();
    SecureLogger.info("Encryption system initialized.");

  } catch (e) {
    SecureLogger.error("Encryption init error: $e");
  }

  try {
    if (!kIsWeb) {
      // BUG-085: SafeDevice calls can fail on older Android APIs or emulators.
      // We log platform errors and allow startup to continue safely rather than blocking app launch.
      final bool jailbroken = await SafeDevice.isJailBroken;
      if (jailbroken) {
        isCompromised = true;
        errorMessage = "Compromised device detected. The Oracle cannot run in this environment.";
      }
    }
  } catch (e, st) {
    SecureLogger.error("Jailbreak verification failed, continuing safely: $e\n$st");
  }

  if (isCompromised) {
    // Log compromised status but allow custom recovery path
    SecureLogger.warning("Startup alert: $errorMessage");
  }


  try {
    SecureLogger.info("Verifying Firebase setup...");
    if (Firebase.apps.isEmpty) {
      FirebaseOptions? options;
      try {
        options = DefaultFirebaseOptions.currentPlatform;
      } catch (e) {
        SecureLogger.error("Firebase config not available for this platform: $e");
      }
      if (options != null) {
        await Firebase.initializeApp(
          options: options,
        ).timeout(const Duration(seconds: 10));

        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: kIsWeb ? 20 * 1024 * 1024 : Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    }

    if (Firebase.apps.isNotEmpty) {
      firebaseStatus = true;
      try {
        // 🛡️ App Check — centralized, environment-aware
        try {
          await AppCheckConfig.initialize()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          SecureLogger.error("AppCheck initialization error: $e");
        }
        
        if (!kIsWeb) {
          try {
            await FirebaseCrashlytics.instance
                .setCrashlyticsCollectionEnabled(true)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            SecureLogger.error("Crashlytics setup error: $e");
          }
        }

        SecureLogger.info("Firebase verified successfully.");

        // Sync local profile configuration to Firestore now that Firebase is active (Fix silent migration data loss)
        try {
          await UserPreferenceService.syncToFirestore();
        } catch (e) {
          SecureLogger.error("Failed to sync profile to Firestore at startup: $e");
        }

        // 🛡️ ZENITH STRESS DEFENSE: FINAL HARDENING (Points 11 & 12)
        // Initialize forensic shield and remote emergency controls
        final shield = IntegrityShield();
        await shield.runFullScan();
        
        final emergency = EmergencyControlService();
        await emergency.init();

        // 🌧️ Phase 5: Initialize Monsoon Broadcast WebSocket & Poller Engine
        MonsoonBroadcastService().init();

        // 🚨 PANIC ROOM: Check for global kill-switch before mounting UI
        if (emergency.isKillSwitchActive) {
          return InitializationResult(
            hiveSuccess: true,
            firebaseSuccess: true,
            isKillSwitchActive: true,
            maintenanceMessage: emergency.maintenanceMessage,
          );
        }

        // 🛡️ Initialize security stack AFTER Firebase is ready
        try {
          await ZenithSecurityFacade().initialize()
              .timeout(const Duration(seconds: 10));
          SecureLogger.info("[ZenithSecurity] Stack initialized. Risk: ${ZenithSecurityFacade().shield.riskScore}");
        } catch (e) {
          SecureLogger.error("[ZenithSecurity] Init failed (non-critical): $e");
        }
      } on Exception catch (e) {
        SecureLogger.error("Firebase init error. Proceeding in offline mode.: $e");
      }
    } else {
      SecureLogger.warning("Skipping Firebase initialization due to missing config.");
    }

    if (firebaseStatus) {
      try {
        final remoteConfig = await RemoteConfigService.getInstance();
        await remoteConfig.initialize();
        SecureLogger.bgTask("Remote Config initialized.", tag: "RemoteConfig");
      } catch (e) {
        SecureLogger.warning("Remote Config init failed: $e. Using default values.", tag: "RemoteConfig", isBackground: true);
      }
    }
  } catch (e) {
    SecureLogger.warning("Firebase optional init error: $e", tag: "Firebase", isBackground: true);
  }

  // Option A: Zero-Bundle Server-Driven Sync Engine (2.5s Timeout enforced inside service)
  try {
    SecureLogger.storage("Starting Option A Delta Sync & SQLite Hydration...", tag: "DeltaSync", isBackground: true);
    final deltaSync = DeltaSyncService();
    final bool hasUpdates = await deltaSync.checkForUpdates();
    if (hasUpdates) {
      await deltaSync.performDeltaSync();
    }
    await deltaSync.hydrateMemoryCache();
    SecureLogger.storage("Option A Delta Sync & Hydration Complete.", tag: "DeltaSync", isBackground: true);
  } catch (e) {
    SecureLogger.warning("Option A Delta Sync failed (offline/timeout): $e. Proceeding with existing RAM/SQLite data.", tag: "DeltaSync", isBackground: true);
  }

  SecureLogger.bgTask('Background initialization complete. Firebase: $firebaseStatus', tag: "Startup");
  return InitializationResult(
    hiveSuccess: storageStatus,
    firebaseSuccess: firebaseStatus,
    isCompromised: isCompromised,
    error: errorMessage,
  );

  } catch (e, st) {
    // BUG-125: Catch-all for any unexpected startup anomaly — return a
    // degraded result so the UI can show a fallback screen instead of crashing.
    SecureLogger.error('Critical unexpected startup error', e, st, 'Startup', true);
    return InitializationResult(
      hiveSuccess: storageStatus,
      firebaseSuccess: false,
      error: e.toString(),
    );
  }
}



Future<void> initializeOtherServices() async {
  try {
    if (!kIsWeb) {
      // Initializes ATT (iOS) and UMP (GDPR) before calling MobileAds.instance.initialize()
      await ConsentService().init();
    }
  } catch (e) {
    SecureLogger.error("Ads Init Error: $e");
  }

  try {
    await NotificationService().init();
  } catch (e) {
    SecureLogger.error("Notify Init Error: $e");
  }

  try {
    AnalyticsService().logEvent('app_opened');
  } catch (e) {
    SecureLogger.warning("Failed to log app_opened event: $e");
  }
  
  // Ads & Voice Pre-load
  MonetizationService().loadInterstitialAd();
  MonetizationService().loadRewardedAd();
  
  try {
    await VoiceService().init();
  } catch (e) {
    debugPrint("Voice Init Error: $e");
  }
}


// The thin root MaterialApp — just theming + localization, routes to Splash
class HiddenGemsApp extends ConsumerStatefulWidget {
  const HiddenGemsApp({super.key});

  @override
  ConsumerState<HiddenGemsApp> createState() => _HiddenGemsAppState();
}

class _HiddenGemsAppState extends ConsumerState<HiddenGemsApp> with WidgetsBindingObserver {
  bool _showMainApp = false;
  bool _userDismissedSoftUpdate = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _notifSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // BUG-N01 Fix: Listen for foreground push messages and present a floating Snackbar
    _notifSubscription = NotificationService().onForegroundMessage.listen((message) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted && message.notification != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.notification!.title ?? 'New Notification',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.colors.white),
                ),
                if (message.notification!.body != null)
                  Text(
                    message.notification!.body!,
                    style: TextStyle(color: AppTheme.colors.white70),
                  ),
              ],
            ),
            backgroundColor: AppTheme.colors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: AppTheme.colors.amber,
              onPressed: () {
                final nav = navigatorKey.currentState;
                if (nav != null && message.data['type'] == 'new_booking') {
                  nav.push(MaterialPageRoute(builder: (_) => const BookingInboxScreen()));
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final initAsync = ref.watch(appInitializationProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HiddenGems.lk',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.breezeTheme,
      darkTheme: AppTheme.abyssTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('si'),
        Locale('ta'),
        Locale('ja'),
        Locale('ru'),
        Locale('ko'),
      ],
      locale: locale,
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      home: initAsync.when(
        data: (initState) {
          if (initState.updateType == UpdateType.force) {
            return UpdateScreen(type: UpdateType.force, onMaybeLater: () {});
          }
          if (initState.updateType == UpdateType.soft && !_userDismissedSoftUpdate) {
            return UpdateScreen(
              type: UpdateType.soft,
              onMaybeLater: () => setState(() => _userDismissedSoftUpdate = true),
            );
          }
          if (_showMainApp) {
            return _buildHomeModule(initState.result);
          }
          return SplashScreen(
            onFinish: () => setState(() => _showMainApp = true),
            isReady: true,
          );
        },
        loading: () => SplashScreen(
          onFinish: () => setState(() => _showMainApp = true),
          isReady: false,
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: AppTheme.primaryBlue(context),
          body: GracefulErrorWidget(
            icon: Icons.storage_rounded,
            title: "Oracle Cannot Start",
            subtitle: error.toString(),
            buttonLabel: "Retry",
            onRetry: () => ref.invalidate(appInitializationProvider),
          ),
        ),
      ),
      builder: (context, child) => GlobalScreenshotWrapper(
        child: AppLockWrapper(child: child!),
      ),
    );
  }

  Widget _buildHomeModule(InitializationResult result) {
    if (result.isKillSwitchActive) {
      return Scaffold(
        backgroundColor: AppTheme.colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              result.maintenanceMessage ?? "System maintenance is in progress.",
              style: TextStyle(color: AppTheme.colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (!result.canProceed) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlue(context),
        body: GracefulErrorWidget(
          icon: Icons.storage_rounded,
          title: "Oracle Cannot Start",
          subtitle: result.error ?? "Critical storage error. The Oracle cannot start.",
          buttonLabel: "Retry",
          onRetry: () => ref.invalidate(appInitializationProvider),
        ),
      );
    }

    if (!result.firebaseSuccess) {
      return const HomeScreen(isOffline: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBlue(context),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ModernTracerIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "ORACLE IS THINKING...",
                    style: GoogleFonts.inter(
                      color: AppTheme.modernGreen(context),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBlue(context),
            body: GracefulErrorWidget(
              icon: Icons.wifi_off_rounded,
              title: "Connection Error",
              subtitle: snapshot.error.toString(),
              buttonLabel: "Retry",
              onRetry: () => ref.invalidate(appInitializationProvider),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // User is ALREADY logged in via Firebase / Gmail / Email!
          SecurityOrchestrator().init(user.uid);
          
          // Auto-repair local profile if needed so we don't prompt them again
          final currentProfile = UserPreferenceService.getProfile();
          if (!currentProfile.hasCompletedOnboarding || !currentProfile.hasAgreedToTerms) {
            UserPreferenceService.updateOnboardingCompletion(true);
            UserPreferenceService.updateTermsAgreement(true);
          }
          return const HomeScreen();
        }

        // User is NOT logged in (new user or logged out).
        // They must go through Onboarding -> Language -> Terms -> Login Screen!
        final profile = UserPreferenceService.getProfile();
        if (!profile.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }
        if (profile.languageCode == null) {
          return const LanguageSelectionScreen();
        }
        if (!profile.hasAgreedToTerms) {
          return const TermsScreen();
        }

        return const LoginScreen();
      },
    );
  }
}


class GlobalScreenshotWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalScreenshotWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalScreenshotWrapper> createState() => _GlobalScreenshotWrapperState();
}

class _GlobalScreenshotWrapperState extends ConsumerState<GlobalScreenshotWrapper> with SingleTickerProviderStateMixin {
  final ScreenshotService _screenshotService = ScreenshotService();
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    HapticFeedback.heavyImpact();
    // Trigger Flash
    _flashController.forward(from: 0.0);
    await _screenshotService.captureAndShare(context);
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(screenshotProvider);

    return Screenshot(
      controller: _screenshotService.controller,
      child: Stack(
        children: [
          widget.child,
          if (isVisible)
            Positioned(
              right: 16,
              bottom: 110,
              child: SafeArea(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Material(
                    color: AppTheme.colors.transparent,
                    child: InkWell(
                      onTap: _handleCapture,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: AppTheme.glassDecoration(
                          context,
                          opacity: 0.2, 
                          blur: 30,
                          shape: BoxShape.circle,
                        ).copyWith(
                          border: Border.all(
                            color: AppTheme.primaryBlue(context).withValues(alpha: 0.5), 
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue(context).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Flash Effect Overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              if (_flashController.value == 0) return const SizedBox.shrink();
              return IgnorePointer(
                child: Opacity(
                  opacity: _flashController.value < 0.5 
                      ? _flashController.value * 2 
                      : (1.0 - _flashController.value) * 2,
                  child: Container(
                    color: AppTheme.colors.white,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
