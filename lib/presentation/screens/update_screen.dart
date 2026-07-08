import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/update_service.dart';
import '../../core/config/app_config.dart';
import '../widgets/golden_tracer_indicator.dart';

class UpdateScreen extends StatelessWidget {
  final UpdateType type;
  final VoidCallback onMaybeLater;

  const UpdateScreen({
    super.key,
    required this.type,
    required this.onMaybeLater,
  });

  Future<void> _launchStore(BuildContext context) async {
    final bool isIOS = Platform.isIOS;
    final Uri url = Uri.parse(isIOS 
        ? 'https://apps.apple.com/app/id${AppConfig.appStoreId}'
        : 'https://play.google.com/store/apps/details?id=com.hidden_gems_sl');
        
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Could not open store link.");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open store. Please update manually."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isForce = type == UpdateType.force;

    return PopScope(
      canPop: !isForce,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldColor(context),
        body: Stack(
          fit: StackFit.expand,
          children: [
          // Background Aesthetic
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Theme.of(context).cardColor, 
                  AppTheme.scaffoldColor(context)
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon/Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Text Content
                  Text(
                    isForce ? "An update is required" : "A new version is ready",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isForce
                        ? "Please update the app to continue your journey."
                        : "Better maps, faster AI trips, and improved AR are waiting for you.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  const ModernTracerIndicator(),
                  const SizedBox(height: 48),

                  // Actions
                  Column(
                    children: [
                      _buildButton(
                        context,
                        label: "Update now",
                        isPrimary: true,
                        onTap: () => _launchStore(context),
                      ),
                      if (!isForce) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: onMaybeLater,
                          child: Text(
                            "Maybe later",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required bool isPrimary, required VoidCallback onTap}) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
