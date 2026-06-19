import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows the AR Premium upgrade bottom sheet dialog.
/// Call via: ARUpgradeDialog.show(context, onPreview: ..., onUpgrade: ...)
class ARUpgradeDialog extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onPreview;

  const ARUpgradeDialog({
    super.key,
    required this.onUpgrade,
    required this.onPreview,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpgrade,
    required VoidCallback onPreview,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ARUpgradeDialog(
        onUpgrade: onUpgrade,
        onPreview: onPreview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Icon with gold glow
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB300).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏛', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Unlock AR Heritage Mode',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Experience Sri Lanka as it looked thousands of years ago.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Feature list
          _featureRow('🏺', 'Ancient 3D Reconstruction'),
          const SizedBox(height: 12),
          _featureRow('🎧', 'Audio Narration (සිංහල / English)'),
          const SizedBox(height: 12),
          _featureRow('📸', 'AR Photo Capture & Social Share'),
          const SizedBox(height: 28),

          // Pricing
          Text(
            'From Rs. 299/month  ·  7-day free trial',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFB300),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onUpgrade();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preview button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onPreview();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Watch 10-sec Preview',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Not now
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.2)),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
