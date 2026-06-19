import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ar_video_content.dart';
import '../services/ar_video_repository.dart';
import 'ar_video_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/widgets/batik_background.dart';

class ARContentPreviewScreen extends StatefulWidget {
  final ARVideoContent content;

  const ARContentPreviewScreen({super.key, required this.content});

  @override
  State<ARContentPreviewScreen> createState() => _ARContentPreviewScreenState();
}

class _ARContentPreviewScreenState extends State<ARContentPreviewScreen> {
  late ARVideoContent _currentContent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.content;
    if (_currentContent.syncPoints.isEmpty) {
      _fetchFullContent();
    }
  }

  Future<void> _fetchFullContent() async {
    setState(() => _isLoading = true);
    final repo = ARVideoRepository();
    final full = await repo.fetchContent(_currentContent.locationId);
    if (mounted) {
      setState(() {
        _currentContent = full;
        _isLoading = false;
      });
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
              height: MediaQuery.of(context).size.height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, AppTheme.sigiriyaOchre(context).withValues(alpha: 0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu, color: AppTheme.sigiriyaOchre(context), size: 80),
                      const SizedBox(height: 20),
                      Text(
                        _currentContent.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInfoRow(Icons.auto_awesome, 'Historical Reconstruction', '720p H.264 Cinematic'),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.record_voice_over, 'Narrative Guidance', 'Bilingual (EN | SI)'),
                        const SizedBox(height: 32),
                        Text(
                          'TIMELINE HIGHLIGHTS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.sigiriyaOchre(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Timeline of sync points
                        SizedBox(
                          height: 120,
                          child: _isLoading 
                            ? Center(child: CircularProgressIndicator(color: AppTheme.sigiriyaOchre(context)))
                            : _currentContent.syncPoints.isEmpty 
                              ? Center(child: Text('Data portal loading...', style: GoogleFonts.inter(color: Colors.white38)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _currentContent.syncPoints.length,
                                  itemBuilder: (context, index) {
                                    final sp = _currentContent.syncPoints[index];
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${sp.timeSeconds}s',
                                            style: GoogleFonts.outfit(color: AppTheme.sigiriyaOchre(context), fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            sp.textEn,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ARVideoScreen(content: _currentContent),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sigiriyaOchre(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              'ENTER TIME PORTAL',
                              style: GoogleFonts.outfit(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
