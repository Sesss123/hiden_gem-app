import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/update_service.dart';
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
        ? 'https://apps.apple.com/app/id6400000000' // TODO: Replace with actual App Store ID
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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isForce) {
          SystemNavigator.pop();
        }
      },
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.modernGreen(context).withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 60,
                      color: AppTheme.modernGreen(context),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Text Content
                  Text(
                    "ORACLE UPGRADE",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isForce 
                        ? "A CRITICAL UPDATE IS REQUIRED TO CONTINUE YOUR JOURNEY."
                        : "A NEW VERSION OF THE ORACLE IS AVAILABLE WITH ENHANCED VISION.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary(context),
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  const ModernTracerIndicator(),
                  const SizedBox(height: 48),

                  // Actions
                  Column(
                    children: [
                      _buildButton(
                        context,
                        label: "UPDATE NOW",
                        isPrimary: true,
                        onTap: () => _launchStore(context),
                      ),
                      if (!isForce) ...[
                        const SizedBox(height: 16),
                        _buildButton(
                          context,
                          label: "MAYBE LATER",
                          isPrimary: false,
                          onTap: onMaybeLater,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: isPrimary 
            ? BoxDecoration(
                color: AppTheme.modernGreen(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.modernGreen(context).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              )
            : BoxDecoration(
                border: Border.all(color: AppTheme.borderColor(context)),
                borderRadius: BorderRadius.circular(12),
              ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isPrimary ? Colors.black : AppTheme.textPrimary(context),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
