import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
              backgroundColor: AppTheme.colors.transparent,
              elevation: 0,
              content: OracleUI.glassContainer(
                padding: const EdgeInsets.all(16),
                borderColor: AppTheme.colors.redAccent.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.colors.redAccent),
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

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter your registered email address first."),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset instructions sent to $email."),
          backgroundColor: AppTheme.modernGreen(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send reset email: ${_mapAuthException(e)}"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              borderColor: AppTheme.colors.redAccent.withValues(alpha: 0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, color: AppTheme.colors.redAccent, size: 48),
                  const SizedBox(height: 24),
                  OracleUI.neonText(
                    "ZENITH LOCK ACTIVE",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.colors.redAccent, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Multiple failed attempts detected.\nNeural link restricted to prevent brute force.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 13),
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
                          color: AppTheme.colors.white,
                          letterSpacing: 4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "TIME REMAINING",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.colors.white24, letterSpacing: 2),
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
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
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
            backgroundColor: AppTheme.colors.transparent,
            elevation: 0,
            content: OracleUI.glassContainer(
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.colors.redAccent.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.colors.redAccent),
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
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return "Invalid email or password. Please try again.";
        case 'user-disabled':
          return "This account has been disabled.";
        case 'email-already-in-use':
          return "The email address is already in use by another account.";
        case 'weak-password':
          return "The password provided is too weak.";
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'network-request-failed':
          return "Network request failed. Please check your internet connection.";
        case 'too-many-requests':
          return "Too many requests. Please try again later.";
        case 'operation-not-allowed':
          return "This operation is not allowed.";
        default:
          return e.message ?? "An authentication error occurred.";
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.explore_rounded,
                        size: 52,
                        color: primaryColor,
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 34, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: "HiddenGems", style: TextStyle(color: AppTheme.textPrimary(context))),
                        TextSpan(
                          text: ".SL", 
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    "SECURE ACCESS REQUIRED",
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      color: AppTheme.textSecondary(context).withValues(alpha: 0.6), 
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.colors.grey[900]!.withValues(alpha: 0.6) : AppTheme.colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.secondaryBorder(context),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
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
                            if (_isLoginMode) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Forgot Access Key?",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: AppTheme.colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading 
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode ? "INITIATE ACCESS" : "CREATE NEW IDENTITY",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800, 
                                          letterSpacing: 1, 
                                          fontSize: 13, 
                                          color: AppTheme.colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isLoginMode = !_isLoginMode);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary(context),
                              ),
                              child: Text(
                                _isLoginMode ? "New explorer? Generate identity" : "Existing explorer? Validate access",
                                style: GoogleFonts.inter(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.textSecondary(context).withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.secondaryBorder(context))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "THIRD-PARTY AUTH", 
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary(context).withValues(alpha: 0.4), 
                            fontSize: 9, 
                            fontWeight: FontWeight.w800, 
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.secondaryBorder(context))),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.colors.grey[900]!.withValues(alpha: 0.6) : AppTheme.colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.secondaryBorder(context),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: AppTheme.colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.colors.white.withValues(alpha: 0.1) : AppTheme.colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "G",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Continue with Google Account", 
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, 
                                fontSize: 13,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                  
                  const SizedBox(height: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      validator: validator,
      style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 14),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: AppTheme.textSecondary(context).withValues(alpha: 0.6), 
          fontSize: 11, 
          fontWeight: FontWeight.w700, 
          letterSpacing: 0.5,
        ),
        prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.7), size: 18),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.secondaryBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.colors.redAccent.withValues(alpha: 0.4)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.colors.redAccent.withValues(alpha: 0.6)),
        ),
        errorStyle: GoogleFonts.inter(
          color: AppTheme.colors.redAccent.withValues(alpha: 0.8), 
          fontSize: 10, 
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.colors.white.withValues(alpha: 0.02) : AppTheme.colors.black.withValues(alpha: 0.02),
      ),
    );
  }
}
