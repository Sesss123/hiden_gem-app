import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:io';
import 'dart:ui';
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
import 'core/utils/secure_logger.dart';
import 'core/utils/encryption_util.dart';
import 'package:safe_device/safe_device.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
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
      debugPrint("Suppressing Crashlytics error during reporting: $e");
    }
    
    // 2. Log to Analytics (Safe for Web/Mobile)
    try {
      AnalyticsService().logEvent('runtime_error', parameters: {
        'exception': errorDetails.exceptionAsString(),
        'stack': errorDetails.stack.toString(),
      });
    } catch (_) {}

    // 3. Keep Default Behavior (Show Red Screen/Overflow Indicator)
    FlutterError.presentError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (e) {
      debugPrint("Suppressing Crashlytics error in dispatcher: $e");
    }
    return true;
  };
  
  debugPrint("Main Entry: Initializing core storage...");
  
  // 1. Initialize Essential Local Storage (Hive) - MUST be first
  try {
    await TripCacheService.init();
    await UserPreferenceService.init();
    await UserPreferenceService.ensureProfileLoaded();
    debugPrint("Core storage ready.");
  } catch (e) {
    debugPrint("CRITICAL Hive Init Error: $e");
  }

  // Apply Strict HTTPS Security and SSL Pinning configuration globally
  if (!kIsWeb) {
    HttpOverrides.global = SecureNetworkOverrides();
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
    const Duration(seconds: 12),
    onTimeout: () {
      debugPrint("Initialization timed out. Proceeding in fallback mode.");
      return InitializationResult(hiveSuccess: true, firebaseSuccess: false);
    },
  );

  UpdateType updateType = UpdateType.none;
  if (result.firebaseSuccess) {
    initializeOtherServices();
    try {
      updateType = await UpdateService().checkUpdate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => UpdateType.none,
      );
    } catch (_) {}
  }
  return AppInitState(result: result, updateType: updateType);
});

Future<InitializationResult> performInitialization() async {
  bool firebaseStatus = false;
  bool isCompromised = false;
  bool storageStatus = TripCacheService.isInitialized;
  String? errorMessage;

  try {
    AppConfig.validate();
  } catch (e) {
    debugPrint("Validation error: $e");
    return InitializationResult(
      hiveSuccess: storageStatus,
      firebaseSuccess: false,
      error: e.toString(),
    );
  }

  debugPrint("Background initialization started. Web mode: $kIsWeb");

  try {
    // Initialize Encryption System early
    await EncryptionUtil.init();
    debugPrint("Encryption system initialized.");
  } catch (e) {
    debugPrint("Encryption init error: $e");
  }

  try {
    if (!kIsWeb) {
      bool jailbroken = await SafeDevice.isJailBroken;
      if (jailbroken) {
        isCompromised = true;
        errorMessage = "Compromised device detected. The Oracle cannot run in this environment.";
      }
    }
  } catch (e) {
    debugPrint("Jailbreak detection error: $e");
  }

  if (isCompromised) {
    return InitializationResult(
      hiveSuccess: true, // Hive was already opened in main
      firebaseSuccess: false,
      isCompromised: true,
      error: errorMessage,
    );
  }

  try {
    debugPrint("Initializing Firebase...");
    FirebaseOptions? options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } catch (e) {
      debugPrint("Firebase config not available for this platform: $e");
    }

    if (options != null) {
      try {
        await Firebase.initializeApp(
          options: options,
        ).timeout(const Duration(seconds: 15));

        // 🛡️ App Check — centralized, environment-aware
        await AppCheckConfig.initialize()
            .timeout(const Duration(seconds: 8));
        
        if (!kIsWeb) {
          try {
            await FirebaseCrashlytics.instance
                .setCrashlyticsCollectionEnabled(true)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint("Crashlytics setup error: $e");
          }
        }

        // Enable Firestore offline persistence
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          // For web: use IndexedDb for better performance than memory cache
          cacheSizeBytes: kIsWeb ? 20 * 1024 * 1024 : Settings.CACHE_SIZE_UNLIMITED,
        );

        firebaseStatus = true;
        debugPrint("Firebase initialized successfully.");

        // 🛡️ ZENITH STRESS DEFENSE: FINAL HARDENING (Points 11 & 12)
        // Initialize forensic shield and remote emergency controls
        final shield = IntegrityShield();
        await shield.runFullScan();
        
        final emergency = EmergencyControlService();
        await emergency.init();

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
          debugPrint("[ZenithSecurity] Stack initialized. Risk: ${ZenithSecurityFacade().shield.riskScore}");
        } catch (e) {
          debugPrint("[ZenithSecurity] Init failed (non-critical): $e");
        }
      } on Exception catch (e) {
        debugPrint("Firebase init error: $e. Proceeding in offline mode.");
      }
    } else {
      debugPrint("Skipping Firebase initialization due to missing config.");
    }

    if (firebaseStatus) {
      try {
        final remoteConfig = await RemoteConfigService.getInstance();
        await remoteConfig.initialize();
        debugPrint("Remote Config initialized.");
      } catch (e) {
        debugPrint("Remote Config init failed: $e. Using default values.");
      }
    }
  } catch (e) {
    debugPrint("Firebase optional init error: $e");
  }

  debugPrint("Background initialization complete. Firebase: $firebaseStatus");
  return InitializationResult(
    hiveSuccess: storageStatus,
    firebaseSuccess: firebaseStatus,
    isCompromised: isCompromised,
    error: errorMessage,
  );
}

void initializeOtherServices() {
  // These don't need to block UI rendering
  try {
    if (!kIsWeb) {
      MobileAds.instance.initialize();
    }
  } catch (e) {
    SecureLogger.error("Ads Init Error: $e");
  }

  try {
    NotificationService().init();
  } catch (e) {
    SecureLogger.error("Notify Init Error: $e");
  }

  try {
    AnalyticsService().logEvent('app_opened');
  } catch (_) {}
  
  // Ads & Voice Pre-load
  MonetizationService().loadInterstitialAd();
  MonetizationService().loadRewardedAd();
  
  try {
    VoiceService().init();
  } catch (e) {
    debugPrint("Voice Init Error: $e");
  }

  // Global Error Boundary is already set in main()
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeNotifierProvider);
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
        loading: () => SplashScreen(onFinish: () {}, isReady: false),
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
      builder: (context, child) => GlobalScreenshotWrapper(child: child!),
    );
  }

  Widget _buildHomeModule(InitializationResult result) {
    if (result.isKillSwitchActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              result.maintenanceMessage ?? "System maintenance is in progress.",
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
            body: Center(child: Text("Connection Error: ${snapshot.error}")),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          SecurityOrchestrator().init(user.uid);
          
          final currentProfile = UserPreferenceService.getProfile();
          if (!currentProfile.hasAgreedToTerms) {
            return const TermsScreen();
          }
          return const HomeScreen();
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
    final isVisible = ref.watch(screenshotNotifierProvider);

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
                    color: Colors.transparent,
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
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
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
                    color: Colors.white,
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
