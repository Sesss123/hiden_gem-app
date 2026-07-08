import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/datasources/user_preference_service.dart';
import '../widgets/custom_buttons.dart';
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
                    Icon(Icons.error_outline_rounded, color: AppTheme.colors.redAccent),
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
                  Icon(Icons.lock_clock_rounded, color: AppTheme.colors.redAccent, size: 48),
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
                  Icon(Icons.error_outline_rounded, color: AppTheme.colors.redAccent),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              // Centered brand header
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
                    const SizedBox(height: 18),
                    Text(
                      _isLoginMode ? "Welcome to Hidden Gems" : "Create your account",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                        letterSpacing: -0.3,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                    const SizedBox(height: 6),
                    Text(
                      _isLoginMode ? "Sri Lanka's AI travel companion" : "Start planning your Sri Lanka trip",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 120.ms),
                    const SizedBox(height: 24),

                    // Segmented Sign in / Create account switch
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted(context),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildModeTab(context, label: "Sign in", selected: _isLoginMode)),
                          Expanded(child: _buildModeTab(context, label: "Create account", selected: !_isLoginMode)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isLoginMode) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: "Name",
                            icon: Icons.person_outline_rounded,
                            autofillHints: [AutofillHints.name],
                            validator: (v) => v!.isEmpty ? "Identifier required" : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: [AutofillHints.email],
                          validator: (v) => !v!.contains("@") ? "Invalid address" : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          autofillHints: _isLoginMode ? [AutofillHints.password] : [AutofillHints.newPassword],
                          validator: (v) => v!.length < 6 ? "Insufficient complexity" : null,
                        ),
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 6),
                          Text(
                            "At least 6 characters",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
                                "Forgot password?",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        PrimaryButton(
                          label: _isLoginMode ? "Sign in" : "Create account",
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleSubmit,
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(child: Divider(color: AppTheme.secondaryBorder(context))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "or continue with",
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppTheme.secondaryBorder(context))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.colors.white.withValues(alpha: 0.03) : AppTheme.colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppTheme.secondaryBorder(context),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: AppTheme.colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _handleGoogleSignIn,
                              borderRadius: BorderRadius.circular(100),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: _GoogleLogo()),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Google",
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
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                    ],
                  ),
                ),
              ),
            );
          },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary(context),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          validator: validator,
          style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600, fontSize: 14),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: GoogleFonts.inter(
              color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
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
            fillColor: AppTheme.surfaceMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(BuildContext context, {required String label, required bool selected}) {
    final onSelected = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        if (selected) return;
        HapticFeedback.lightImpact();
        setState(() => _isLoginMode = !_isLoginMode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : AppTheme.colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected ? AppTheme.softShadow : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? onSelected : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

/// The multi-color Google "G" mark, drawn locally so the login screen
/// doesn't need a bundled logo asset or an SVG dependency.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.42;
    final ringRadius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    Paint ringPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const degToRad = 3.14159265358979 / 180;
    void drawArc(Color color, double startDeg, double sweepDeg) {
      canvas.drawArc(rect, startDeg * degToRad, sweepDeg * degToRad, false, ringPaint(color));
    }

    // Four ring quadrants matching the brand mark, small gaps between.
    drawArc(const Color(0xFF4285F4), -20, 86); // blue: top-right
    drawArc(const Color(0xFF34A853), 70, 86); // green: bottom-right
    drawArc(const Color(0xFFFBBC05), 160, 86); // yellow: bottom-left
    drawArc(const Color(0xFFEA4335), 250, 86); // red: top-left

    // Crossbar of the "G", from center out to the ring's right edge.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.1,
        center.dy - strokeWidth * 0.5,
        size.width / 2 - center.dx + strokeWidth * 0.6,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
