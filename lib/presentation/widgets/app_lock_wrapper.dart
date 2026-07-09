import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:hidden_gems_sl/data/datasources/user_preference_service.dart';

import 'package:google_fonts/google_fonts.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isSupported = true;
  // Guards against overlapping auth.authenticate() calls — rapid
  // background/foreground transitions (e.g. pulling down the notification
  // shade) fire didChangeAppLifecycleState() multiple times in quick
  // succession, and calling authenticate() while a prior call is still
  // showing its system prompt throws authInProgress instead of queuing.
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSupportAndAuthenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isSupported) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isAuthenticated && _isSupported) {
        if (UserPreferenceService.getProfile().isAppLockEnabled) {
          _authenticate();
        } else {
          setState(() {
            _isAuthenticated = true;
          });
        }
      }
    }
  }
  
  Future<void> _checkSupportAndAuthenticate() async {
    if (kIsWeb) {
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }
    
    _isSupported = await auth.isDeviceSupported();
    if (_isSupported && UserPreferenceService.getProfile().isAppLockEnabled) {
      _authenticate();
    } else {
      setState(() {
        _isAuthenticated = true; // Bypass if biometrics are unavailable or disabled in settings
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to access Hidden Gems SL',
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: $e");
      // Fallback
      authenticated = true;
    } finally {
      _isAuthenticating = false;
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isAuthenticated)
          Positioned.fill(
            child: Container(
              color: AppTheme.colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint, size: 80, color: AppTheme.colors.orange),
                    const SizedBox(height: 24),
                    Text(
                      "App Locked",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _authenticate,
                      child: Text("Unlock Now", style: GoogleFonts.outfit(color: AppTheme.colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
