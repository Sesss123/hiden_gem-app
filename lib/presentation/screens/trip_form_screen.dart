import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/limit_reached_dialog.dart';
import '../../core/services/usage_limiter_service.dart';
import '../../data/datasources/monetization_service.dart';
import 'loading_plan_screen.dart';
import '../widgets/soft_upgrade_nudge_card.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _budgetController = TextEditingController(text: '25000');

  String _origin = "";
  String _destination = "";
  int _days = 2;
  String _groupType = "couple";
  String _pace = "balanced";
  String _style = "comfort";
  final List<String> _interests = [];

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _groupOptions = ["solo", "couple", "family", "friends"];
  final List<String> _paceOptions = ["relaxed", "balanced", "packed"];
  final List<String> _styleOptions = ["budget", "comfort", "luxury"];
  final List<String> _interestOptions = [
    "Adventure 🧗", "Food 🍛", "Wildlife 🐘", "Photography 📸",
    "Village Experiences 🌾",
  ];

  // Sri Lanka cities for autocomplete — offline, no network needed
  static const List<String> _sriLankaCities = [
    'Colombo', 'Galle', 'Kandy', 'Ella', 'Nuwara Eliya', 'Jaffna', 'Trincomalee',
    'Batticaloa', 'Negombo', 'Anuradhapura', 'Polonnaruwa', 'Sigiriya', 'Dambulla',
    'Matara', 'Hambantota', 'Tangalle', 'Mirissa', 'Weligama', 'Hikkaduwa',
    'Unawatuna', 'Arugam Bay', 'Habarana', 'Pinnawala', 'Ratnapura', 'Kurunegala',
    'Bandarawela', 'Badulla', 'Monaragala', 'Ampara', 'Mannar', 'Vavuniya',
    'Kataragama', 'Tissamaharama', 'Bentota', 'Beruwala', 'Chilaw', 'Kalpitiya',
    'Puttalam', 'Avissawella', 'Hatton', 'Nanu Oya', 'Ohiya',
    'BIA / Airport', 'Katunayake',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  bool _validateStep() {
    if (_currentStep == 0) {
      final cleanOrigin = _origin.trim().toLowerCase();
      final cleanDest = _destination.trim().toLowerCase();

      if (cleanOrigin.isEmpty) {
        _showValidationError("Please select or enter a starting point.");
        return false;
      }
      if (cleanDest.isEmpty) {
        _showValidationError("Please select or enter a destination.");
        return false;
      }

      final validCities = _sriLankaCities.map((c) => c.toLowerCase()).toSet();
      if (!validCities.contains(cleanOrigin)) {
        _showValidationError("'$cleanOrigin' is not a supported Sri Lankan city. Please select from the dropdown.");
        return false;
      }
      if (!validCities.contains(cleanDest)) {
        _showValidationError("'$cleanDest' is not a supported Sri Lankan city. Please select from the dropdown.");
        return false;
      }
      if (cleanOrigin == cleanDest) {
        _showValidationError("Starting point and destination cannot be the same.");
        return false;
      }
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: AppTheme.secondaryBorder(context))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () {
            HapticFeedback.lightImpact();
            _prevStep();
          },
        ),
        title: _buildProgressBar(),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              "Exit", 
              style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _currentStep = i);
        },
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 140,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBorder(context),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: 140 * ((_currentStep + 1) / _totalSteps),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _stepLayout(
      title: "Where should we\nguide you?",
      subtitle: "The Essentials",
      content: Column(
        children: [
          const SoftUpgradeNudgeCard(featureName: 'AI Travel Plans'),
          _cityAutocomplete(
            label: "Starting Point",
            hint: "Airport, Colombo...",
            icon: Icons.flight_takeoff,
            onSelected: (v) => _origin = v,
            onChanged: (v) => _origin = v,
            initialText: _origin,
          ),
          const SizedBox(height: 16),
          _cityAutocomplete(
            label: "Destination",
            hint: "Ella, Galle, Kandy...",
            icon: Icons.place_outlined,
            onSelected: (v) => _destination = v,
            onChanged: (v) => _destination = v,
            initialText: _destination,
          ),
          const SizedBox(height: 16),
          _outlinedTile(icon: Icons.calendar_month, label: "Start Date", value: _formatDate(_startDate), onTap: _pickDate),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _stepLayout(
      title: "Define the vibe of\nyour journey.",
      subtitle: "Budget & Style",
      content: Column(
        children: [
          _itemHeader("DAILY DURATION"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("How many days?", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary(context))),
              Text("$_days Days", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          Slider(
            value: _days.toDouble(),
            min: 1, max: 21, divisions: 20,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            onChanged: (v) => setState(() => _days = v.toInt()),
          ),
          const SizedBox(height: 24),
          _choiceGroup("Travel Standard", _styleOptions, _style, (v) => setState(() => _style = v)),
          const SizedBox(height: 24),
          _budgetField(),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _stepLayout(
      title: "With whom do you\ntravel?",
      subtitle: "Companions & Pace",
      content: Column(
        children: [
          _choiceGroup("Companions", _groupOptions, _groupType, (v) => setState(() => _groupType = v)),
          const SizedBox(height: 24),
          _choiceGroup("Travel Pace", _paceOptions, _pace, (v) => setState(() => _pace = v)),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return _stepLayout(
      title: "What stirs your\nsoul?",
      subtitle: "Interests & Passions",
      content: Wrap(
        spacing: 8,
        runSpacing: 12,
        children: _interestOptions.map((opt) {
          final isSelected = _interests.contains(opt);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => isSelected ? _interests.remove(opt) : _interests.add(opt));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.secondaryBorder(context),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.textSecondary(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _stepLayout({required String title, required String subtitle, required Widget content}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle.toUpperCase(), 
            style: GoogleFonts.inter(
              fontSize: 10, 
              fontWeight: FontWeight.w800, 
              color: AppTheme.textSecondary(context), 
              letterSpacing: 2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
          const SizedBox(height: 4),
          Text(
            title, 
            style: GoogleFonts.outfit(
              fontSize: 28,
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          content.animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _cityAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onSelected,
    required Function(String) onChanged,
    String initialText = "",
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialText),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<String>.empty();
        return _sriLankaCities.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        onSelected(selection);
        onChanged(selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.secondaryBorder(context)),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            autofillHints: const [AutofillHints.addressCity],
            style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              labelText: label,
              labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, fontWeight: FontWeight.w600),
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.3), fontSize: 14),
              border: InputBorder.none,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: MediaQuery.of(context).size.width - 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.secondaryBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final city = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(city, style: GoogleFonts.outfit(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _budgetField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ESTIMATED BUDGET", 
            style: GoogleFonts.inter(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _budgetController,
            autofillHints: const [AutofillHints.transactionAmount],
            style: GoogleFonts.outfit(
              fontSize: 32, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.textPrimary(context),
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "LKR ", 
              prefixStyle: TextStyle(color: AppTheme.textSecondary(context)),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceGroup(String label, List<String> options, String current, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _itemHeader(label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = current == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.secondaryBorder(context),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.textSecondary(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _itemHeader(String label) => Text(
    label.toUpperCase(), 
    style: GoogleFonts.inter(
      fontSize: 10, 
      fontWeight: FontWeight.bold, 
      color: AppTheme.textSecondary(context), 
      letterSpacing: 2,
    ),
  );

  Widget _outlinedTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondaryBorder(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary(context))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.secondaryBorder(context))),
      ),
      child: PrimaryButton(
        label: _currentStep == _totalSteps - 1 ? "CONSULT ORACLE" : "CONTINUE",
        onPressed: () {
          HapticFeedback.mediumImpact();
          _nextStep();
        },
      ),
    );
  }

  void _submit() async {
    // Show a small processing overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
    );

    // AI Trip Limits check
    final canGenerate = await UsageLimiterService.canGenerateAiTrip();
    
    // Close loading
    if (mounted) Navigator.pop(context);

    if (!canGenerate) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => LimitReachedDialog(
            featureName: 'AI Trips',
            onWatchAd: () {
              MonetizationService().showRewardedAd(
                onRewardEarned: (reward) async {
                  await UsageLimiterService.provideBonusAiTrip();
                  if (!mounted || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bonus Trip Unlocked! Try submitting again.")),
                  );
                },
              );
            },
          ),
        );
      }
      return;
    }

    final budgetLkr = int.tryParse(_budgetController.text) ?? 25000;
    
    // Valid trip, record the usage
    await UsageLimiterService.incrementAiTrip();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingPlanScreen(
            origin: _origin.isEmpty ? "Colombo" : _origin,
            destination: _destination.isEmpty ? "Kandy" : _destination,
            days: _days,
            startDate: _formatDate(_startDate),
            groupType: _groupType,
            pace: _pace,
            budgetLkr: budgetLkr,
            style: _style,
            transport: "car",
            interests: _interests.isEmpty ? ["Nature 🌿"] : _interests,
            mustInclude: const [],
            avoid: const [],
            constraints: const [],
          ),
        ),
      );
    }
  }
}
