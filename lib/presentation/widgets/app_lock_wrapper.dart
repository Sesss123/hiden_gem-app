import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:hidden_gems_sl/core/theme/app_theme.dart';

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
        _authenticate();
      }
    }
  }
  
  Future<void> _checkSupportAndAuthenticate() async {
    _isSupported = await auth.isDeviceSupported();
    if (_isSupported) {
      _authenticate();
    } else {
      setState(() {
        _isAuthenticated = true; // Bypass if biometrics are unavailable
      });
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to access Hidden Gems SL',
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: $e");
      // Fallback
      authenticated = true;
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
