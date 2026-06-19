import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../widgets/golden_tracer_indicator.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/user_preference_service.dart';
import 'home_screen.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
      
      if (mounted) {
        final profile = UserPreferenceService.getProfile();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => profile.hasAgreedToTerms 
                ? const HomeScreen() 
                : const TermsScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('ZENITH_LOCKOUT')) {
          final seconds = int.parse(errorStr.split('|').last);
          _showLockoutOverlay(seconds);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: OracleUI.glassContainer(
                padding: const EdgeInsets.all(16),
                borderColor: Colors.redAccent.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Authentication Failed: ${_mapAuthException(e)}",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLockoutOverlay(int seconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Center(
            child: OracleUI.glassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(32),
              borderColor: Colors.redAccent.withValues(alpha: 0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 24),
                  OracleUI.neonText(
                    "ZENITH LOCK ACTIVE",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Multiple failed attempts detected.\nNeural link restricted to prevent brute force.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  TweenAnimationBuilder<Duration>(
                    duration: Duration(seconds: seconds),
                    tween: Tween(begin: Duration(seconds: seconds), end: Duration.zero),
                    onEnd: () => Navigator.pop(context),
                    builder: (BuildContext context, Duration value, Widget? child) {
                      final minutes = value.inMinutes;
                      final secondsRemaining = value.inSeconds % 60;
                      return Text(
                        "$minutes:${secondsRemaining.toString().padLeft(2, '0')}",
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "TIME REMAINING",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      setState(() => _isLoading = false);

      if (user != null && mounted) {
        final profile = UserPreferenceService.getProfile();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => profile.hasAgreedToTerms 
                ? const HomeScreen() 
                : const TermsScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In was cancelled.")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: OracleUI.glassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: Colors.redAccent.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Google Sign-In Failed: ${_mapAuthException(e)}",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  String _mapAuthException(Object e) {
    final message = e.toString().toLowerCase();
    if (message.contains('invalid-credential') || message.contains('wrong-password') || message.contains('user-not-found')) {
      return "Invalid email or password. Please try again.";
    } else if (message.contains('user-disabled')) {
      return "This account has been disabled.";
    } else if (message.contains('email-already-in-use')) {
      return "The email address is already in use by another account.";
    } else if (message.contains('weak-password')) {
      return "The password provided is too weak.";
    } else if (message.contains('invalid-email')) {
      return "Please enter a valid email address.";
    } else if (message.contains('network-request-failed')) {
      return "Network request failed. Please check your internet connection.";
    } else if (message.contains('too-many-requests')) {
      return "Too many requests. Please try again later.";
    } else if (message.contains('operation-not-allowed')) {
      return "This operation is not allowed.";
    }
    return e.toString().split(']').last.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: OracleUI.auraBackground(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Glowing Logo Portal
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: OracleUI.glassContainer(
                      padding: const EdgeInsets.all(28),
                      borderRadius: BorderRadius.circular(40),
                      borderColor: primaryColor.withValues(alpha: 0.3),
                      child: Icon(
                        Icons.explore_rounded,
                        size: 56,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 4.seconds, color: Colors.white24),
                
                const SizedBox(height: 32),
                
                // Typography Matrix
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
                    children: [
                      const TextSpan(text: "TripMe", style: TextStyle(color: Colors.white)),
                      TextSpan(
                        text: ".ai", 
                        style: TextStyle(
                          color: primaryColor,
                          shadows: [
                            Shadow(color: primaryColor.withValues(alpha: 0.6), blurRadius: 20)
                          ]
                        )
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                
                const SizedBox(height: 8),
                
                Text(
                  "SECURE NEURAL ACCESS REQUIRED",
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    color: primaryColor.withValues(alpha: 0.4), 
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                
                const SizedBox(height: 48),
                
                // Login/Register Neural Matrix
                OracleUI.premiumGlassCard(
                  padding: const EdgeInsets.all(28),
                  radius: BorderRadius.circular(32),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLoginMode) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: "USER IDENTIFIER",
                              icon: Icons.person_outline_rounded,
                              autofillHints: [AutofillHints.name],
                              validator: (v) => v!.isEmpty ? "Identifier required" : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildTextField(
                            controller: _emailController,
                            label: "ORACLE ADDRESS (EMAIL)",
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                            validator: (v) => !v!.contains("@") ? "Invalid address" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: "ACCESS KEY",
                            icon: Icons.security_rounded,
                            isPassword: true,
                            autofillHints: _isLoginMode ? [AutofillHints.password] : [AutofillHints.newPassword],
                            validator: (v) => v!.length < 6 ? "Insufficient complexity" : null,
                          ),
                          const SizedBox(height: 32),
                          
                          // Neural Portal Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                shadowColor: primaryColor.withValues(alpha: 0.5),
                              ),
                              child: _isLoading 
                                  ? const ModernTracerIndicator()
                                  : OracleUI.neonText(
                                      _isLoginMode ? "INITIATE ACCESS" : "CREATE NEW IDENTITY",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w900, 
                                        letterSpacing: 1.5, 
                                        fontSize: 13, 
                                        color: Colors.black,
                                      ),
                                      glowColor: Colors.white38,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => _isLoginMode = !_isLoginMode);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.white38),
                            child: Text(
                              _isLoginMode ? "New explore? Generate identity" : "Existing explorer? Validate access",
                              style: GoogleFonts.inter(
                                fontSize: 12, 
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 400.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.05))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "THIRD-PARTY AUTH", 
                        style: GoogleFonts.inter(
                          color: Colors.white10, 
                          fontSize: 9, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.05))),
                  ],
                ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
                
                const SizedBox(height: 24),
                
                // Google Sign In (Zenith Gloss)
                OracleUI.premiumGlassCard(
                  padding: EdgeInsets.zero,
                  radius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "G",
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Continue with Google Account", 
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, 
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 800.ms),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.5), size: 18),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        errorStyle: GoogleFonts.inter(color: Colors.redAccent.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.01),
      ),
    );
  }
}
