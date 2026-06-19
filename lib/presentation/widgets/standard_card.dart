import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class StandardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? tag;
  final Color? tagColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const StandardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.tag,
    this.tagColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.glassDecoration(
          context,
          opacity: isDark ? 0.05 : 0.02,
          color: isDark ? null : Colors.white,
        ).copyWith(
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Section
            SizedBox(
              width: 120,
              height: 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (tagColor ?? AppTheme.modernGreen(context)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag!.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tagColor ?? AppTheme.modernGreen(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 16),
            ]
          ],
        ),
      ),
    );
  }
}
