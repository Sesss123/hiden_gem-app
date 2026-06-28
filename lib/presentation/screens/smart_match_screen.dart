import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/oracle_guardian.dart';

class SmartMatchScreen extends StatefulWidget {
  const SmartMatchScreen({super.key});

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> {
  int _currentStep = 0;
  final List<String> _interests = [];
  String? _tripStyle;
  String? _budget;
  bool _isAnalyzing = false;

  final List<Map<String, dynamic>> _allInterests = [
    {"label": "Heritage", "icon": Icons.account_balance_rounded, "image": "https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?auto=format&fit=crop&w=800&q=80"},
    {"label": "Wildlife", "icon": Icons.pets_rounded, "image": "https://images.unsplash.com/photo-1564760055775-d63b17a55c44?auto=format&fit=crop&w=800&q=80"},
    {"label": "Adventure", "icon": Icons.terrain_rounded, "image": "https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=800&q=80"},
    {"label": "Culinary", "icon": Icons.restaurant_rounded, "image": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80"},
    {"label": "Spiritual", "icon": Icons.self_improvement_rounded, "image": "https://images.unsplash.com/photo-1545389336-cf090694435e?auto=format&fit=crop&w=800&q=80"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _isAnalyzing ? _buildAnalyzingView() : _buildQuestionnaire(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaire() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        _buildProgressIndicator(),
        const SizedBox(height: 48),
        Expanded(
          child: IndexedStack(
            index: _currentStep,
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
        ),
        _buildBottomNav(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _currentStep >= index ? AppTheme.modernGreen(context) : AppTheme.glassBorder(context),
            borderRadius: BorderRadius.circular(2),
            boxShadow: _currentStep == index ? [
              BoxShadow(color: AppTheme.modernGreen(context).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)
            ] : null,
          ),
        ),
      )),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OracleUI.neonText("EXPERIENCES", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 16),
        Text("What defines your journey's soul?", style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 16)),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: _allInterests.map((interest) {
            final isSelected = _interests.contains(interest['label']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => isSelected ? _interests.remove(interest['label']) : _interests.add(interest['label']));
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected) 
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.modernGreen(context).withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds)
                     .fadeOut(duration: 2.seconds),
                  OracleUI.glassContainer(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(28),
                    showGlow: isSelected,
                    glowColor: AppTheme.modernGreen(context),
                    borderGradient: isSelected ? OracleUI.neonAccentGradient : null,
                    image: DecorationImage(
                      image: NetworkImage(interest['image']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: isSelected ? 0.3 : 0.6),
                        BlendMode.darken,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(interest['icon'], color: isSelected ? AppTheme.modernGreen(context) : Colors.white70, size: 32),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                interest['label'].toUpperCase(), 
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : Colors.white70, 
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OracleUI.neonText("TRAVEL RHYTHM", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 16),
        Text("What is your exploration frequency?", style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 16)),
        const SizedBox(height: 48),
        _buildRhythmOption("LEISURE", "Mellow, meditative, and grounded.", Icons.nightlight_round_sharp, 0.3),
        _buildRhythmOption("BALANCED", "A harmonious flux of discovery.", Icons.wb_sunny_rounded, 0.6),
        _buildRhythmOption("EXPEDITION", "High-frequency, adrenaline-fueled.", Icons.bolt_rounded, 1.0),
      ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.05);
  }

  Widget _buildRhythmOption(String label, String description, IconData icon, double intensity) {
    final isSelected = _tripStyle == label;
    final primary = AppTheme.modernGreen(context);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _tripStyle = label);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: OracleUI.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          showGlow: isSelected,
          glowColor: primary,
          borderGradient: isSelected ? OracleUI.neonAccentGradient : null,
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44, height: 44,
                    child: CircularProgressIndicator(
                      value: intensity,
                      strokeWidth: 2,
                      backgroundColor: AppTheme.secondaryBorder(context).withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(isSelected ? primary : AppTheme.textSecondary(context).withValues(alpha: 0.2)),
                    ),
                  ),
                  Icon(icon, color: isSelected ? primary : AppTheme.textSecondary(context).withValues(alpha: 0.3), size: 20),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.outfit(color: isSelected ? primary : AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(description, style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              if (isSelected) 
                Icon(Icons.check_circle_rounded, color: primary, size: 20).animate().scale().fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OracleUI.neonText("FINANCIAL RESONANCE", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 16),
        Text("Select your preferred investment tier.", style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 16)),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(child: _buildBudgetOption("VALUE", "Verified budget guides.", "\$")),
            const SizedBox(width: 20),
            Expanded(child: _buildBudgetOption("PREMIUM", "Elite comfort & expert.", "\$\$\$")),
          ],
        ),
        const SizedBox(height: 32),
        OracleUI.glassContainer(
          padding: const EdgeInsets.all(20),
          opacity: 0.03,
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.accentOchre(context), size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Oracle Matching weights guide reputation higher than price for optimal safety.",
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.4), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.05);
  }

  Widget _buildBudgetOption(String label, String description, String symbol) {
    final isSelected = _budget == label;
    final primary = AppTheme.modernGreen(context);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        setState(() => _budget = label);
      },
      child: OracleUI.premiumGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        showGlow: isSelected,
        child: Column(
          children: [
            Text(
              symbol, 
              style: GoogleFonts.outfit(
                color: isSelected ? primary : AppTheme.textSecondary(context).withValues(alpha: 0.2), 
                fontSize: 40, 
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              )
            ),
            const SizedBox(height: 20),
            Text(label, style: GoogleFonts.outfit(color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context).withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.4), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          IconButton(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          )
        else
          const SizedBox(width: 48),
        
        ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.modernGreen(context),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            _currentStep == 2 ? "INITIALIZE MATCH" : "CONTINUE",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _analyzePreferences();
    }
  }

  Future<void> _analyzePreferences() async {
    final guardian = OracleGuardian();
    
    // Security Certification
    if (!await guardian.certifyTransition('QUESTIONNAIRE', 'ANALYZING')) {
      guardian.secureLog('Unauthorized analysis transition', isCritical: true);
    }

    setState(() => _isAnalyzing = true);
    
    // Simulated Neural Processing
    await Future.delayed(3.seconds);
    
    final obfuscatedStatus = guardian.obfuscateStatus('SUCCESS');
    guardian.secureLog("Neural matching completed: $obfuscatedStatus");

    if (mounted) {
      _showResult();
    }
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.modernGreen(context).withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.radar_rounded, color: AppTheme.modernGreen(context), size: 48)
                .animate(onPlay: (c) => c.repeat())
                .scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), curve: Curves.easeInOut)
                .shimmer(duration: 2.seconds),
          ),
          const SizedBox(height: 48),
          OracleUI.neonText("ORACLE NEURAL MATCH...", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 6, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 16),
          Text("Synchronizing traveler profiles and regional affinities.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.38), fontSize: 13)),
        ],
      ),
    );
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Center(
        child: OracleUI.premiumGlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          showGlow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, color: AppTheme.modernGreen(context), size: 48),
              const SizedBox(height: 24),
              OracleUI.neonText(
                "ORACLE MATCH COMPLETE",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Text(
                "Based on your preference for ${_interests.join(', ')} and a ${_tripStyle?.toLowerCase()} pace:",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 8,
                children: [
                   _whyTag("Cultural Specialist"),
                   _whyTag("Nature Expert"),
                   _whyTag("Optimal Proximity"),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to marketplace
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("VIEW RECOMMENDATIONS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whyTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
