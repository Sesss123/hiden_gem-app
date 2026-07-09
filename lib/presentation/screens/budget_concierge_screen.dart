import 'package:hidden_gems_sl/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/expense_service.dart';
import '../../data/models/expense_model.dart';
import '../../core/config/app_config.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';

class BudgetConciergeScreen extends ConsumerStatefulWidget {
  const BudgetConciergeScreen({super.key});

  @override
  ConsumerState<BudgetConciergeScreen> createState() =>
      _BudgetConciergeScreenState();
}

class _BudgetConciergeScreenState extends ConsumerState<BudgetConciergeScreen> {
  List<Expense> _expenses = [];
  double _totalSpent = 0.0;
  String _aiAdvice = "Analyzing your spending patterns...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await ExpenseService.getExpenses();
    final total = await ExpenseService.getTotalSpent();
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _totalSpent = total;
        _isLoading = false;
      });
      _getAIAdvice();
    }
  }

  Future<void> _getAIAdvice() async {
    try {
      if (AppConfig.geminiApiKey.isNotEmpty) {
        final model = GenerativeModel(
            model: AppConfig.llmModelName, apiKey: AppConfig.geminiApiKey);
        final prompt = """
          You are 'Oracle Budget Concierge' for a traveler in Sri Lanka.
          The user has spent total $_totalSpent LKR so far.
          Expenses: ${_expenses.map((e) => "${e.description}: ${e.amount}").join(", ")}
          
          Provide a short (2 sentence) cinematic advice on their budget. 
          Focus on value-for-money transport (like using PickMe/Uber vs private tours) 
          and suggest maintaining a sustainable pace.
        """;
        final response = await model.generateContent([Content.text(prompt)]);
        if (mounted && response.text != null) {
          setState(() => _aiAdvice = response.text!);
          return;
        }
      }
    } catch (e) {
      SecureLogger.warning("External LLM skipped or failed: $e",
          tag: "BudgetConcierge");
    }

    // 🏛️ Offline / Self-Hosted Rule-Based Cinematic Fallback
    if (mounted) {
      setState(() => _aiAdvice =
          "Your spending pace aligns well with island travel standards. We recommend utilizing PickMe or Uber for transparent transport fares, and sampling local eateries to maximize your value.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: OracleUI.auraBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _isLoading
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(24),
                        children: [
                          _buildSummaryCard(),
                          SizedBox(height: 24),
                          _buildAIAdviceCard(),
                          SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Recent transactions",
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              IconButton(
                                icon: Icon(Icons.add_circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                                onPressed: _showAddExpenseDialog,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ..._expenses.reversed.toList().asMap().entries.map(
                              (entry) =>
                                  _buildExpenseTile(entry.value, entry.key)),
                        ],
                      ),
                    ),
            ],
          ),
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
            icon: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8)),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Budget concierge",
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Total spent so far",
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            "Rs ${_totalSpent.toStringAsFixed(0)}",
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary(context),
                fontSize: 28,
                fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text("≈ \$${(_totalSpent / 320).toStringAsFixed(2)} USD",
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAIAdviceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppPaletteDark.card : AppPalette.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppPalette.heroOchre.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.psychology_rounded,
                    color: AppPalette.heroOchre, size: 18)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 3.seconds),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Oracle advice",
                  style: GoogleFonts.inter(
                      color: AppPalette.heroOchre,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  _aiAdvice,
                  style: GoogleFonts.inter(
                      color: AppTheme.colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildExpenseTile(Expense e, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppTheme.colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          _categoryIcon(e.category),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.description,
                    style: GoogleFonts.inter(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                SizedBox(height: 2),
                Text(e.date.toString().split(' ')[0],
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text("Rs ${e.amount.toInt()}",
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (400 + (index * 100)).ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _categoryIcon(ExpenseCategory cat) {
    IconData icon = Icons.receipt_long_rounded;
    Color color = AppTheme.textSecondary(context);
    switch (cat) {
      case ExpenseCategory.food:
        icon = Icons.restaurant_rounded;
        color = AppTheme.colors.orangeAccent;
        break;
      case ExpenseCategory.transport:
        icon = Icons.directions_car_rounded;
        color = AppTheme.colors.blueAccent;
        break;
      case ExpenseCategory.attraction:
        icon = Icons.temple_buddhist_rounded;
        color = Theme.of(context).colorScheme.primary;
        break;
      case ExpenseCategory.lodging:
        icon = Icons.hotel_rounded;
        color = AppTheme.colors.purpleAccent;
        break;
      default:
        icon = Icons.more_horiz_rounded;
        color = AppTheme.colors.grey;
    }
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  void _showAddExpenseDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.food;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            top: 24,
            left: 24,
            right: 24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        borderColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        // SingleChildScrollView — when the keyboard opens for the amount/
        // description fields, the sheet's fixed-height content (title +
        // two fields + spacing + button) can exceed the remaining screen
        // height and overflow rather than resize, since a plain Column
        // inside a MediaQuery-padded sheet has nowhere to shrink to.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: 32),
              Text("Log transaction",
                  style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 17)),
              SizedBox(height: 40),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "What was the purpose?",
                  hintStyle: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                  prefixIcon: Icon(Icons.edit_note_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3))),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Amount (LKR)",
                  hintStyle: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                  prefixIcon: Icon(Icons.payments_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3))),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0 && descController.text.isNotEmpty) {
                      final expense = Expense(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        description: descController.text,
                        amount: amount,
                        category: selectedCat,
                        date: DateTime.now(),
                      );
                      await ExpenseService.addExpense(expense);
                      // Refresh the parent screen's list/total BEFORE popping —
                      // popping triggers the bottom sheet's whenComplete(),
                      // which disposes descController/amountController
                      // synchronously. Calling _loadData() (a setState on the
                      // parent) after that dispose, while the sheet is still
                      // mid-teardown, raced with the framework's own rebuild
                      // and threw "TextEditingController used after disposed" /
                      // RenderFlex overflow / stale InheritedElement asserts.
                      if (!context.mounted) return;
                      await _loadData();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Save expense",
                    style: AppTheme.buttonLabelStyle(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      descController.dispose();
      amountController.dispose();
    });
  }
}
