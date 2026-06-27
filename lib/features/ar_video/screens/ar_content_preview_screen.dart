import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ar_video_content.dart';
import '../services/ar_video_repository.dart';
import 'ar_video_screen.dart';
import '../services/subtitle_service.dart'; // NarrationLang enum
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/widgets/batik_background.dart';
import '../../../../core/utils/secure_logger.dart';

class ARContentPreviewScreen extends StatefulWidget {
  final ARVideoContent content;

  const ARContentPreviewScreen({super.key, required this.content});

  @override
  State<ARContentPreviewScreen> createState() => _ARContentPreviewScreenState();
}

class _ARContentPreviewScreenState extends State<ARContentPreviewScreen> {
  late ARVideoContent _currentContent;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBookmarked = false;
  String _selectedLanguage = 'EN'; // 'EN' or 'SI'

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
    _checkBookmarkStatus();
    if (_currentContent.syncPoints.isEmpty) {
      _fetchFullContent();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('bookmarked_ar_portals') ?? [];
      if (mounted) {
        setState(() {
          _isBookmarked = list.contains(_currentContent.locationId);
        });
      }
    } catch (e) {
      SecureLogger.error('Error checking bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('bookmarked_ar_portals') ?? [];
      setState(() {
        if (_isBookmarked) {
          list.remove(_currentContent.locationId);
          _isBookmarked = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_currentContent.name} removed from bookmarks'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          list.add(_currentContent.locationId);
          _isBookmarked = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_currentContent.name} saved to bookmarks!'),
              backgroundColor: AppTheme.sigiriyaOchre(context),
            ),
          );
        }
      });
      await prefs.setStringList('bookmarked_ar_portals', list);
    } catch (e) {
      SecureLogger.error('Error toggling bookmark: $e');
    }
  }

  void _sharePortal() {
    final shareText = 'Check out this amazing 3D AR Time Portal of ${_currentContent.name} on Hidden Gems Sri Lanka!\n'
        'Explore the historical reconstruction timeline by guide ${_currentContent.guideName}.\n'
        'Link: https://hidden-gems-sl.web.app/ar-portal?id=${_currentContent.locationId}';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _addToItinerary() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_currentContent.name} added to your active itinerary!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _fetchFullContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final repo = ARVideoRepository();
      // Fetch with an 8-second timeout fallback
      final full = await repo.fetchContent(_currentContent.locationId)
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() {
          _currentContent = full;
          _isLoading = false;
        });
      }
    } catch (e) {
      SecureLogger.error('Error fetching full AR content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e is TimeoutException 
              ? 'Request timed out. Please check your connection.'
              : 'Failed to retrieve timeline data. Tap retry to load.';
        });
      }
    }
  }

  String _getHeroImage(String locationId) {
    switch (locationId.toLowerCase()) {
      case 'sigiriya':
        return 'assets/images/sigiriya_sunset_bg.jpg';
      case 'ella':
      case 'nine_arch':
        return 'assets/images/ella_nine_arch_bg.jpg';
      case 'galle':
      case 'galle_fort':
        return 'assets/images/galle_fort_bg.jpg';
      case 'kandy':
      case 'kandy_lake':
        return 'assets/images/kandy_lake_bg.jpg';
      case 'nuwara_eliya':
        return 'assets/images/nuwara_eliya_tea_bg.jpg';
      default:
        return 'assets/images/sri_lanka_live_base.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BatikBackground(
        child: Stack(
          children: [
            // Hero image/gradient background
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.42,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _getHeroImage(_currentContent.locationId),
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black87,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          Icons.history_edu,
                          color: AppTheme.sigiriyaOchre(context),
                          size: 64,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentContent.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 15, offset: Offset(2, 2))
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _currentContent.duration.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: AppTheme.sigiriyaOchre(context),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Guide details row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                Icons.person,
                                'Narrative Expert',
                                _currentContent.guideName,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.auto_awesome, 'Historical Reconstruction', '720p H.264 Cinematic'),
                        const SizedBox(height: 16),
                        
                        // Description Field
                        Text(
                          'PORTAL DESCRIPTION',
                          style: GoogleFonts.outfit(
                            color: AppTheme.sigiriyaOchre(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentContent.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Language Toggle and Timeline Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TIMELINE HIGHLIGHTS',
                              style: GoogleFonts.outfit(
                                color: AppTheme.sigiriyaOchre(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLanguageButton('EN', 'English'),
                                  _buildLanguageButton('SI', 'සිංහල'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Timeline of sync points
                        SizedBox(
                          height: 125,
                          child: _isLoading 
                            ? Center(child: CircularProgressIndicator(color: AppTheme.sigiriyaOchre(context)))
                            : _hasError
                              ? _buildErrorWidget()
                              : _currentContent.syncPoints.isEmpty 
                                ? Center(child: Text('No timeline markers found.', style: GoogleFonts.inter(color: Colors.white38)))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _currentContent.syncPoints.length,
                                    itemBuilder: (context, index) {
                                      final sp = _currentContent.syncPoints[index];
                                      return _buildSyncPointCard(sp);
                                    },
                                  ),
                        ),
                        const SizedBox(height: 24),

                        // Actions Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionIconButton(
                                icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                                label: 'Bookmark',
                                active: _isBookmarked,
                                color: AppTheme.sigiriyaOchre(context),
                                onTap: _toggleBookmark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionIconButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                active: false,
                                color: Colors.blueAccent,
                                onTap: _sharePortal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionIconButton(
                                icon: Icons.calendar_today_rounded,
                                label: 'Itinerary',
                                active: false,
                                color: Colors.green,
                                onTap: _addToItinerary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Main action button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || _hasError ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ARVideoScreen(
                                    content: _currentContent,
                                    initialLang: _selectedLanguage == 'EN' 
                                        ? NarrationLang.english 
                                        : NarrationLang.sinhala,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.blur_on, color: Colors.black, size: 24),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sigiriyaOchre(context),
                              disabledBackgroundColor: Colors.white10,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                            ),
                            label: Text(
                              'ENTER TIME PORTAL',
                              style: GoogleFonts.outfit(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String code, String label) {
    final active = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.sigiriyaOchre(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: active ? Colors.black : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.4) : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? color : Colors.white70,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? color : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Connection Problem',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _errorMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _fetchFullContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'RETRY',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPointCard(SyncPoint sp) {
    final activeText = _selectedLanguage == 'EN' ? sp.textEn : sp.textSi;
    return GestureDetector(
      onTap: () => _showSyncPointDetails(sp),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${sp.timeSeconds}s',
                  style: GoogleFonts.outfit(
                    color: AppTheme.sigiriyaOchre(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.6),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedLanguage == 'EN' ? sp.textSi : sp.textEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncPointDetails(SyncPoint sp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.grey[950],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'TIMESTAMP: ${sp.timeSeconds} SECONDS',
                      style: GoogleFonts.outfit(
                        color: AppTheme.sigiriyaOchre(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Historical Narrative (English)',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sp.textEn,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ඓතිහාසික විස්තරය (සිංහල)',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sp.textSi.isNotEmpty ? sp.textSi : 'විස්තරය ඇතුලත් කර නොමැත.',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
