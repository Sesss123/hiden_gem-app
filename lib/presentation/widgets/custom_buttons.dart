import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Refresh pill button: flat brand-primary fill, fully rounded, sentence-case
/// label. Both buttons below share this shape — the old gradient + ALL CAPS
/// treatment is gone (see "what changed" notes in the UI refresh mockups).
class ModernGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const ModernGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: onPressed != null ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.colors.transparent,
          foregroundColor: onPrimary,
          shadowColor: AppTheme.colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: onPrimary),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: AppTheme.buttonLabelStyle(context).copyWith(color: onPrimary)),
                ],
              ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: onPressed != null ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.colors.transparent,
          foregroundColor: onPrimary,
          shadowColor: AppTheme.colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                ),
              )
            : Text(label, style: AppTheme.buttonLabelStyle(context).copyWith(color: onPrimary)),
      ),
    );
  }
}
