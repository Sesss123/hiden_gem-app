import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ar_video_content.dart';
import '../services/ar_video_repository.dart';
import 'ar_content_preview_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/widgets/batik_background.dart';

class ARVideoLibraryScreen extends StatelessWidget {
  const ARVideoLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ARVideoRepository();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TIME TRAVEL PORTALS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: BatikBackground(
        child: SafeArea(
          child: StreamBuilder<List<ARVideoContent>>(
            stream: repository.streamAllEnabled(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppTheme.sigiriyaOchre(context)));
              }

              final items = snapshot.data ?? [];
              
              if (items.isEmpty) {
                return _buildEmptyState(context);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildPortalCard(context, items[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, ARVideoContent content) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ARContentPreviewScreen(content: content),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.glassDecoration(context, opacity: 0.15).copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [Colors.black54, AppTheme.sigiriyaOchre(context).withValues(alpha: 0.2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.history_toggle_off,
                    color: AppTheme.sigiriyaOchre(context).withValues(alpha: 0.6),
                    size: 48,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'AR Core Ready',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: Colors.white24, size: 64),
          const SizedBox(height: 24),
          Text(
            'The portals are closed for now',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new historical vistas',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
