import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/savor_lanka_service.dart';
import '../../data/models/food_model.dart';
import '../../core/services/voice_recipe_service.dart';
import '../../data/repositories/food_repository.dart';
import '../../core/theme/app_theme.dart';
import 'real_time_food_scanner_screen.dart';
import '../../l10n/app_localizations.dart';

class SavorLankaScreen extends ConsumerStatefulWidget {
  const SavorLankaScreen({super.key});

  @override
  ConsumerState<SavorLankaScreen> createState() => _SavorLankaScreenState();
}

class _SavorLankaScreenState extends ConsumerState<SavorLankaScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInit = false;
  bool _isAnalyzing = false;
  FoodModel? _result;
  late final SavorLankaService _savorService;
  final VoiceRecipeService _voiceRecipeService = VoiceRecipeService();
  bool _isSaved = false;
  final String _spicePreference = 'Medium';
  final String _userMode = 'Tourist';

  @override
  void initState() {
    super.initState();
    _savorService = SavorLankaService();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  bool _isInitializingCamera = false;

  Future<void> _initCamera() async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _isInitializingCamera = false;
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _isInitializingCamera = false;
        return;
      }

      // Dispose existing controller if any
      final oldController = _controller;
      if (oldController != null) {
        _controller = null;
        if (mounted) {
          setState(() => _isInit = false);
        }
        await oldController.dispose();
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;

      await controller.initialize();
      if (mounted && _controller == controller) {
        setState(() => _isInit = true);
      }
    } catch (e, st) {
      SecureLogger.error("Camera init error", e, st, "SavorLankaScreen");
    } finally {
      _isInitializingCamera = false;
    }
  }

  @override
  void dispose() {
    _voiceRecipeService.stopCooking();
    _voiceRecipeService.dispose();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e, st) { SecureLogger.error("Exception caught: $e\n$st"); }
    final controller = _controller;
    _controller = null;
    _isInit = false;
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // BUG FIX: these were bare field assignments with no setState(), so
      // the widget never rebuilt when the app backgrounded — the last
      // camera frame stayed on screen (e.g. visible in the OS app switcher)
      // instead of falling back to the black placeholder container.
      _controller = null;
      if (mounted) {
        setState(() => _isInit = false);
      } else {
        _isInit = false;
      }
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _analyzeFood() async {
    if (_isAnalyzing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      
      final identification = await _savorService.identifyFood(
        imageFile,
        spicePreference: _spicePreference,
        userMode: _userMode,
      );
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _result = identification;
        });

        if (identification != null) {
          _isSaved = FoodRepository.isSaved(identification.id);
          _voiceRecipeService.startCooking(identification);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.oracleLostFocusMessage(e.toString())), backgroundColor: AppTheme.colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isInit && _controller != null
                ? CameraPreview(_controller!)
                : Container(color: AppTheme.colors.black),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.colors.black.withValues(alpha: 0.8),
                      AppTheme.colors.transparent,
                      AppTheme.colors.transparent,
                      AppTheme.colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildLiveAiBanner(),
                  const Spacer(),
                  if (_result != null) _buildResultCard(),
                  const SizedBox(height: 24),
                  if (_result == null) _buildCaptureButton(),
                  if (_result != null) _buildNeuralVoiceController(),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            if (_isAnalyzing) _buildScanningAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.colors.white.withValues(alpha: 0.9)),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              OracleUI.neonText(
                AppLocalizations.of(context)!.savorLankaAiTitle,
                style: GoogleFonts.outfit(
                  color: AppTheme.colors.white, fontWeight: FontWeight.w900,
                  letterSpacing: 4, fontSize: 13,
                ),
              ),
              SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.culinaryVisionEngineLabel,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900,
                  fontSize: 9, letterSpacing: 3,
                ),
              ),
            ],
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLiveAiBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RealTimeFoodScannerScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.colors.cyanAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.colors.cyanAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.cyanAccent.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.colors.cyanAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.liveRealTimeScannerLabel,
              style: GoogleFonts.outfit(
                color: AppTheme.colors.cyanAccent,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _result!;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: OracleUI.glassContainer(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(28),
          borderRadius: BorderRadius.circular(40),
          showGlow: true,
          borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(res),
              SizedBox(height: 12),
              _buildNutritionReliability(res.nutritionReliability, res.reliabilityReason),
              SizedBox(height: 24),
              _buildNeuralReasoningCard(res.detectionBasis, res.confidenceLabel),
              
              SizedBox(height: 24),
              _buildFreshnessQualityLayer(res),
              SizedBox(height: 16),
              _buildHygieneIntegrityLayer(res),
              
              SizedBox(height: 24),
              _buildMetricsDashboard(res),
              Divider(color: AppTheme.colors.white.withValues(alpha: 0.05), height: 40),
              
              _buildCrossMatchEngine(res),
              SizedBox(height: 24),
              
              _buildAuthenticityScore(res.authenticityScore.toDouble(), res.culinaryStyle, res.variationNote),
              SizedBox(height: 32),
              
              _buildHeritageNarrativeEngine(res),
              SizedBox(height: 32),
              
              if (res.missingCompanions.isNotEmpty) ...[
                _buildCulinaryGapPairingEngine(res),
                SizedBox(height: 32),
              ],
              
              _buildNutritionHub(res),
              SizedBox(height: 32),
              _buildIngredientInference(res, onEdit: (newList) {
                setState(() {
                  _result = res.copyWith(confirmedIngredients: newList);
                });
              }),
              
              if (res.spiceRefactorAdvice.isNotEmpty) ...[
                SizedBox(height: 24),
                _buildRecipeRefactorEngine(res),
              ],
              
              SizedBox(height: 40),
              _buildActionBar(res),
              SizedBox(height: 40),
              
              if (res.mealContext != 'Standalone') ...[
                _buildMealContext(res.mealContext, res.supportingItems),
                SizedBox(height: 32),
              ],
              
              _buildSectionTitle("PREPARATION ENGINE"),
              SizedBox(height: 16),
              _buildRecipeEngine(res),
              
              if (res.proTips.isNotEmpty) ...[
                SizedBox(height: 32),
                _buildOracleInsights(res.proTips),
              ],
              
              if (res.substitutions.isNotEmpty) ...[
                SizedBox(height: 32),
                _buildSubstitutionsCarousel(res.substitutions),
              ],
              
              SizedBox(height: 32),
              _buildDietaryBadges(res.dietaryBadges),
              const SizedBox(height: 24),
              _buildAIInformationDisclaimer(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scaleY(begin: 0.9, curve: Curves.easeOutBack);
  }

  Widget _buildHeroHeader(FoodModel res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfidenceBadge(res.confidence, res.confidenceLabel),
                  OracleUI.neonText(
                    res.name.toUpperCase(),
                    style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  SizedBox(height: 8),
                  _buildRegionBadge(res.primaryRegion, res.secondaryInfluences),
                ],
              ),
            ),
            Column(
              children: [
                _buildConfidenceBadge(res.confidence, res.confidenceLabel),
                const SizedBox(height: 8),
                _buildSaveButton(res),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          res.description,
          style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildRegionBadge(String primary, List<String> influences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary, size: 10),
              SizedBox(width: 4),
              Text(primary.toUpperCase(), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
        if (influences.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.influencesLabel(influences.join(', ')),
            style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 8, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidenceBadge(double confidence, String label) {
    final Color color = confidence > 0.8 ? AppTheme.colors.greenAccent : (confidence > 0.5 ? AppTheme.colors.orangeAccent : AppTheme.colors.redAccent);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.outfit(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          SizedBox(height: 2),
          Text("${(confidence * 100).toInt()}%", style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNutritionReliability(String reliability, String reason) {
    final Color color = reliability == 'High' ? AppTheme.colors.greenAccent : (reliability == 'Moderate' ? AppTheme.colors.orangeAccent : AppTheme.colors.redAccent);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.security_rounded, color: color, size: 14),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.nutritionReliabilityLabel(reliability), style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                if (reason.isNotEmpty) Text(reason, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralReasoningCard(String basis, String label) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
              SizedBox(width: 10),
              OracleUI.neonText(AppLocalizations.of(context)!.neuralReasoningLabel, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            basis.isEmpty ? AppLocalizations.of(context)!.aiVisualMarkersFallback(label) : basis,
            style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticityScore(double score, String style, String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.authenticityIntelligenceTitle),
        SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOchre(context).withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.accentOchre(context).withValues(alpha: 0.3), width: 2),
              ),
              child: Center(
                child: Text(score.toStringAsFixed(1), style: GoogleFonts.outfit(color: AppTheme.accentOchre(context), fontSize: 20, fontWeight: FontWeight.w900)),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style.toUpperCase(), style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  if (note.isNotEmpty) Text(note, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientInference(FoodModel res, {required Function(List<String>) onEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)!.ingredientCertaintyTitle),
            IconButton(
              onPressed: () => _showEditIngredientsDialog(res.confirmedIngredients, onEdit),
              icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        SizedBox(height: 16),
        _ingredientTier(AppLocalizations.of(context)!.ingredientTierConfirmed, res.confirmedIngredients, AppTheme.colors.greenAccent),
        SizedBox(height: 12),
        _ingredientTier(AppLocalizations.of(context)!.ingredientTierLikely, res.likelyIngredients, AppTheme.colors.orangeAccent),
        if (res.optionalIngredients.isNotEmpty) ...[
          SizedBox(height: 12),
          _ingredientTier(AppLocalizations.of(context)!.ingredientTierOptional, res.optionalIngredients, AppTheme.colors.blueAccent),
        ],
      ],
    );
  }

  void _showEditIngredientsDialog(List<String> current, Function(List<String>) onSave) {
    final controller = TextEditingController(text: current.join(', '));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.black,
        surfaceTintColor: AppTheme.colors.transparent,
        title: Text(
          AppLocalizations.of(context)!.manualCulinaryOverrideTitle,
          style: GoogleFonts.outfit(color: AppTheme.colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: GoogleFonts.inter(color: AppTheme.colors.white70),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.refineIngredientsHint,
            hintStyle: TextStyle(color: AppTheme.colors.white24),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.colors.white12), borderRadius: BorderRadius.circular(15)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: AppTheme.colors.white.withValues(alpha: 0.05),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButtonUppercaseAlt, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () {
              final list = controller.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
              onSave(list);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: AppTheme.colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context)!.applyOverrideButton, style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _ingredientTier(String label, List<String> items, Color color) {
    if (items.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) => Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Text(item, style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 11)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMealContext(String mealContext, List<String> supporting) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, color: AppTheme.colors.blueAccent, size: 18),
              SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.mealContextLabel(mealContext), style: GoogleFonts.outfit(color: AppTheme.colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          if (supporting.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.supportingElementsLabel, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(supporting.join(" • "), style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildFreshnessQualityLayer(FoodModel res) {
    final Color color = res.freshnessIndex > 80 ? AppTheme.colors.greenAccent : (res.freshnessIndex > 50 ? AppTheme.colors.orangeAccent : AppTheme.colors.redAccent);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: color, size: 20),
                  SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.visualFreshnessQualityLabel, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("${res.freshnessIndex}%", style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _buildQualityChip(AppLocalizations.of(context)!.qualityColonLabel(res.visualQuality), color),
              SizedBox(width: 8),
              _buildQualityChip(AppLocalizations.of(context)!.textureColonLabel(res.visualTextureStatus), color),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: res.freshnessIndex / 100,
              backgroundColor: AppTheme.colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          if (res.freshnessNote.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              res.freshnessNote,
              style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(label.toUpperCase(), style: GoogleFonts.outfit(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildHeritageNarrativeEngine(FoodModel res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_edu_rounded, color: AppTheme.accentOchre(context), size: 20),
            SizedBox(width: 12),
            OracleUI.neonText(AppLocalizations.of(context)!.heritageNarrativeEngineTitle, style: GoogleFonts.outfit(color: AppTheme.accentOchre(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4)),
          ],
        ),
        SizedBox(height: 20),
        if (res.verifiedHeritage.isNotEmpty)
          _buildHeritageSection(AppLocalizations.of(context)!.verifiedLegacyTitle, res.verifiedHeritage, Icons.verified_user_rounded, AppTheme.colors.blueAccent),
        if (res.regionalTradition.isNotEmpty)
          _buildHeritageSection(AppLocalizations.of(context)!.regionalTraditionTitle, res.regionalTradition, Icons.place_rounded, AppTheme.colors.greenAccent),
        if (res.folkloreNarrative.isNotEmpty)
          _buildHeritageSection(AppLocalizations.of(context)!.folkloreNarrativeTitle, res.folkloreNarrative, Icons.auto_stories_rounded, AppTheme.colors.purpleAccent),
      ],
    );
  }

  Widget _buildHeritageSection(String title, String content, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: 10),
              Text(title, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildCulinaryGapPairingEngine(FoodModel res) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.colors.cyanAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.colors.cyanAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.extension_rounded, color: AppTheme.colors.cyanAccent, size: 20),
              SizedBox(width: 12),
              OracleUI.neonText(AppLocalizations.of(context)!.culinaryGapPairingEngineTitle, style: GoogleFonts.outfit(color: AppTheme.colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
            ],
          ),
          SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.missingCompanionsLabel, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: res.missingCompanions.map((e) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(e, style: GoogleFonts.inter(color: AppTheme.colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
          if (res.pairingNotes.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.engineNotesLabel, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(res.pairingNotes, style: GoogleFonts.inter(color: AppTheme.colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeRefactorEngine(FoodModel res) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.colors.orangeAccent.withValues(alpha: 0.1), AppTheme.colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: AppTheme.colors.orangeAccent, size: 22),
              SizedBox(width: 12),
              OracleUI.neonText(AppLocalizations.of(context)!.recipeRefactorEngineTitle, style: GoogleFonts.outfit(color: AppTheme.colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, color: AppTheme.colors.white38, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.spiceRefactorAdvice,
                    style: GoogleFonts.inter(color: AppTheme.colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (res.personalizedSteps.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.refactoredStepsForYouLabel, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
            SizedBox(height: 12),
            ...res.personalizedSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("•", style: TextStyle(color: AppTheme.colors.orangeAccent, fontSize: 18)),
                  SizedBox(width: 12),
                  Expanded(child: Text(step, style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 13, height: 1.5))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsDashboard(FoodModel res) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricTile(Icons.schedule_rounded, "${res.prepTimeMinutes}m", l10n.prepMetricLabel),
        _metricTile(Icons.restaurant_menu_rounded, "${res.cookTimeMinutes}m", l10n.cookMetricLabel),
        _metricTile(Icons.bolt_rounded, res.difficultyLevel, l10n.levelMetricLabel),
        _metricTile(Icons.local_fire_department_rounded, "${res.estimatedCalories}", l10n.calMetricLabel),
      ],
    );
  }

  Widget _metricTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildNutritionHub(FoodModel res) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _macroBadge("P", "${res.protein}g", l10n.proteinLabel)),
            Expanded(child: _macroBadge("C", "${res.carbs}g", l10n.carbsLabel)),
            Expanded(child: _macroBadge("F", "${res.fat}g", l10n.fatLabel)),
            Expanded(child: _macroBadge("Fi", "${res.fiber}g", l10n.fiberLabel)),
          ],
        ),
        SizedBox(height: 20),
        _buildHealthRatingBar(res.healthRating),
      ],
    );
  }

  Widget _macroBadge(String initial, String value, String label) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(color: AppTheme.colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label.toUpperCase(), style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 7, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildHealthRatingBar(int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.healthRatingLabel, style: GoogleFonts.outfit(color: AppTheme.colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(AppLocalizations.of(context)!.healthRatingValueLabel(rating), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: rating / 10,
            backgroundColor: AppTheme.colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeEngine(FoodModel res) {
    return ListenableBuilder(
      listenable: _voiceRecipeService,
      builder: (context, _) {
        final steps = _voiceRecipeService.isSinhala 
            ? (res.recipeStepsSi ?? res.recipeSteps)
            : res.recipeSteps;
            
        return Column(
          children: steps.asMap().entries.map((entry) {
            int idx = entry.key;
            bool isCurrent = _voiceRecipeService.currentStep == idx;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent 
                      ? Theme.of(context).colorScheme.primary 
                      : AppTheme.colors.white.withValues(alpha: 0.05),
                    width: isCurrent ? 2 : 1,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: -5,
                    )
                  ] : [],
                ),
                child: OracleUI.glassContainer(
                  padding: EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepIndicator(idx + 1, isCurrent: isCurrent),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            color: isCurrent ? AppTheme.colors.white : AppTheme.colors.white70, 
                            fontSize: 13, 
                            height: 1.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (idx * 100).ms, duration: 400.ms).slideX(begin: 0.1);
          }).toList(),
        );
      }
    );
  }

  Widget _stepIndicator(int step, {bool isCurrent = false}) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          "$step", 
          style: GoogleFonts.outfit(
            color: isCurrent ? AppTheme.colors.black : Theme.of(context).colorScheme.primary, 
            fontSize: 12, 
            fontWeight: FontWeight.w900
          )
        ),
      ),
    );
  }

  Widget _buildOracleInsights(List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OracleUI.neonText(AppLocalizations.of(context)!.oracleInsightsTitle, style: GoogleFonts.outfit(color: AppTheme.accentOchre(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 16),
        ...tips.map((tip) => Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentOchre(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.accentOchre(context).withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.accentOchre(context), size: 16),
              SizedBox(width: 16),
              Expanded(child: Text(tip, style: GoogleFonts.inter(color: AppTheme.accentOchre(context).withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSubstitutionsCarousel(List<String> subs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.globalSubstitutionsTitle),
        SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              return Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [AppTheme.colors.tealAccent.withValues(alpha: 0.05), AppTheme.colors.tealAccent.withValues(alpha: 0.1)],
                  ),
                  border: Border.all(color: AppTheme.colors.tealAccent.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Text(subs[idx], style: GoogleFonts.outfit(color: AppTheme.colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryBadges(List<String> badges) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((badge) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(badge, style: GoogleFonts.inter(color: AppTheme.colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildNeuralVoiceController() {
    return ListenableBuilder(
      listenable: _voiceRecipeService,
      builder: (context, _) {
        final isPlaying = _voiceRecipeService.isPlaying;
        final isSi = _voiceRecipeService.isSinhala;
        final l10n = AppLocalizations.of(context)!;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Language Toggle
              _neuralActionBtn(
                onTap: _voiceRecipeService.toggleLanguage,
                icon: Icons.translate_rounded,
                label: isSi ? l10n.sinhalaLabel : l10n.englishLabel,
                isActive: isSi,
              ),
              const Spacer(),
              // Controls
              _neuralActionBtn(
                onTap: _voiceRecipeService.previousStep,
                icon: Icons.fast_rewind_rounded,
                label: l10n.backLabel,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _voiceRecipeService.togglePlayPause,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.colors.black,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _neuralActionBtn(
                onTap: _voiceRecipeService.nextStep,
                icon: Icons.fast_forward_rounded,
                label: l10n.nextLabel,
              ),
              const Spacer(),
              // Scan New
              _neuralActionBtn(
                onTap: () => setState(() => _result = null),
                icon: Icons.camera_alt_rounded,
                label: l10n.rescanLabel,
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, duration: 800.ms, curve: Curves.easeOutQuart);
      }
    );
  }

  Widget _neuralActionBtn({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? Theme.of(context).colorScheme.primary : AppTheme.colors.white70, 
              size: 20
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: GoogleFonts.outfit(
                color: isActive ? Theme.of(context).colorScheme.primary : AppTheme.colors.white38, 
                fontSize: 8, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return OracleUI.neonText(
      title,
      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
    );
  }

  Widget _buildAIInformationDisclaimer() {
    return Text(
      AppLocalizations.of(context)!.aiEstimatedValuesDisclaimer,
      style: GoogleFonts.inter(color: AppTheme.colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildSaveButton(FoodModel res) {
    return GestureDetector(
      onTap: () async {
        if (_isSaved) {
          await FoodRepository.deleteFood(res.id);
          if (mounted) setState(() => _isSaved = false);
        } else {
          await FoodRepository.saveFood(res);
          if (mounted) setState(() => _isSaved = true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isSaved ? Theme.of(context).colorScheme.primary : AppTheme.colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
          color: _isSaved ? AppTheme.colors.black : AppTheme.colors.white,
          size: 20,
        ),
      ),
    );
  }



  Widget _buildCaptureButton() {
    return Center(
      child: GestureDetector(
        onTap: _analyzeFood,
        child: OracleUI.glassContainer(
          width: 84, height: 84,
          padding: EdgeInsets.all(6),
          borderRadius: BorderRadius.circular(42),
          borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.colors.white,
            ),
            child: _isAnalyzing 
              ? Center(child: CircularProgressIndicator(color: AppTheme.colors.black, strokeWidth: 3))
              : Icon(Icons.restaurant_rounded, color: AppTheme.colors.black, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildCrossMatchEngine(FoodModel res) {
    if (res.alternateMatches.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.phase3CrossMatchTitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.colors.deepPurpleAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.colors.deepPurpleAccent.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.visuallySimilarAlternativesLabel,
                style: GoogleFonts.inter(color: AppTheme.colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: res.alternateMatches.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m, style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
              if (res.substitutionReasoning.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.aiCrossMatchReasoningLabel,
                  style: GoogleFonts.inter(color: AppTheme.colors.white38, fontSize: 9, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  res.substitutionReasoning,
                  style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHygieneIntegrityLayer(FoodModel res) {
    final Color color = res.hygieneScore > 90 ? AppTheme.colors.cyanAccent : (res.hygieneScore > 70 ? AppTheme.colors.orangeAccent : AppTheme.colors.redAccent);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: color, size: 20),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.phase6HygienePresentationTitle, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const Spacer(),
              Text("${res.hygieneScore}%", style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          if (res.presentationAnalysis.isNotEmpty)
            Text(
              res.presentationAnalysis,
              style: GoogleFonts.inter(color: AppTheme.colors.white70, fontSize: 12, height: 1.5),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPresentationMiniMetric(AppLocalizations.of(context)!.presentationLabel, res.presentationScore, AppTheme.colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresentationMiniMetric(AppLocalizations.of(context)!.integrityLabel, res.hygieneScore, AppTheme.colors.greenAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationMiniMetric(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.colors.white24, fontSize: 7, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("$score%", style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // End of Result UI

  Widget _buildActionBar(FoodModel res) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildAssistantAction(
            label: _isSaved ? l10n.savedLabel : l10n.saveToCookbookLabel,
            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isSaved ? AppTheme.colors.primary : AppTheme.colors.white24,
            onTap: _toggleSave,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildAssistantAction(
            label: l10n.voiceGuideLabel,
            icon: Icons.graphic_eq_rounded,
            color: AppTheme.colors.blueAccent,
            onTap: () => _voiceRecipeService.startCooking(res),
          ),
        ),
        SizedBox(width: 12),
        _buildAssistantAction(
          label: "",
          icon: Icons.share_rounded,
          color: AppTheme.colors.white10,
          onTap: () {
            SharePlus.instance.share(
              ShareParams(
                text: l10n.savorLankaShareText(res.name, res.hygieneScore.toString()),
                subject: l10n.savorLankaShareSubject,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAssistantAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: label.isEmpty ? 16 : 0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color == AppTheme.colors.white24 ? AppTheme.colors.white : color, size: 20),
            if (label.isNotEmpty) ...[
              SizedBox(width: 12),
              Text(label, style: GoogleFonts.outfit(color: color == AppTheme.colors.white24 ? AppTheme.colors.white : color, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    if (_result == null) return;
    if (_isSaved) {
      await FoodRepository.deleteFood(_result!.id);
    } else {
      await FoodRepository.saveFood(_result!);
    }
    if (!mounted) return;
    setState(() => _isSaved = !_isSaved);
  }

  Widget _buildScanningAnimation() {
    return Positioned.fill(
      child: Container(
        color: AppTheme.colors.black26,
        child: _SavorScannerOverlay(),
      ),
    );
  }
}

class _SavorScannerOverlay extends StatefulWidget {
  @override
  State<_SavorScannerOverlay> createState() => _SavorScannerOverlayState();
}

class _SavorScannerOverlayState extends State<_SavorScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * MediaQuery.of(context).size.height,
              left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.colors.transparent,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      AppTheme.colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
