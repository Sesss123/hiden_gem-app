import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';
import '../../data/datasources/trip_cache_service.dart';
import 'budget_concierge_screen.dart';

class BudgetTrackerScreen extends StatefulWidget {
  final TripPlan plan;
  final String? planId; // If null, it's the volatile 'last plan'
  final String? cacheKey;

  const BudgetTrackerScreen({super.key, required this.plan, this.planId, this.cacheKey});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: "Rs. ", decimalDigits: 0);

  int get _totalSpent => widget.plan.realizedExpenses.fold(0, (sum, e) => sum + e.amountLkr);
  int get _budget => widget.plan.tripSummary.userBudgetLkr;
  double get _percentUsed => _budget > 0 ? (_totalSpent / _budget).clamp(0.0, 1.0) : 0.0;

  void _addExpense() {
    String title = "";
    int amount = 0;
    String category = "food";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 32, right: 32, top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Add expense",
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 32),
              _buildModernInput("Resource Description", (v) => title = v),
              const SizedBox(height: 20),
              _buildModernInput("Amount (LKR)", (v) => amount = int.tryParse(v) ?? 0, isNumber: true),
              const SizedBox(height: 20),
              _buildModernDropdown(category, (v) => setModalState(() => category = v!)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () async {
                    if (title.isNotEmpty && amount > 0) {
                      final newExpense = Expense(
                        id: const Uuid().v4(),
                        title: title,
                        amountLkr: amount,
                        category: category,
                        timestamp: DateTime.now(),
                      );

                      widget.plan.realizedExpenses.add(newExpense);

                      if (widget.planId != null) {
                        await TripCacheService.updateSavedPlan(widget.planId!, widget.plan);
                      } else if (widget.cacheKey != null) {
                        await TripCacheService.cacheLastPlan(widget.plan, widget.cacheKey!);
                      }

                      // Close the sheet BEFORE calling setState() on the
                      // parent screen — the sheet's TextFields own their
                      // TextEditingControllers internally (no `controller:`
                      // passed to _buildModernInput), so triggering a parent
                      // rebuild while the sheet is still mid pop-animation
                      // raced with the sheet's own element teardown and threw
                      // "TextEditingController used after disposed" / stale
                      // InheritedElement asserts.
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (mounted) setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
    );
  }

  Widget _buildModernInput(String label, Function(String) onChanged, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: TextField(
        style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12),
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernDropdown(String current, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: current,
        dropdownColor: AppTheme.colors.white,
        style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: "Category",
          labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12),
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        items: ["food", "transport", "tickets", "misc"].map((c) => DropdownMenuItem(
          value: c,
          child: Text(c.toUpperCase(), style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget = _totalSpent > _budget;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Budget",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppTheme.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary), 
            onPressed: _addExpense
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome, color: AppTheme.colors.purpleAccent), 
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const BudgetConciergeScreen())
            )
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Visualization Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOverBudget
                      ? [AppTheme.colors.redAccent, AppTheme.colors.red[900]!]
                      : [Theme.of(context).colorScheme.primary, AppPalette.rustDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150, height: 150,
                        child: CircularProgressIndicator(
                          value: _percentUsed,
                          strokeWidth: 9,
                          backgroundColor: AppTheme.colors.white.withValues(alpha: 0.15),
                          color: AppTheme.colors.white,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "${(_percentUsed * 100).toInt()}%",
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.colors.white,
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _statItem("Plan limit", _currencyFormat.format(_budget), AppTheme.colors.white)),
                      const SizedBox(width: 16),
                      Expanded(child: _statItem("Spent", _currencyFormat.format(_totalSpent), AppTheme.colors.white)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Expense ledger",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  "${widget.plan.realizedExpenses.length} entries",
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w600)
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.plan.realizedExpenses.isEmpty)
              _buildEmptyState()
            else
              ...widget.plan.realizedExpenses.reversed.map((e) => _buildExpenseItem(e)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: valueColor.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textSecondary(context).withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text(
            "No entries yet",
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _addExpense,
            child: Text(
              "Add first entry",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _categoryIcon(e.category),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 13)
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, h:mma').format(e.timestamp),
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(e.amountLkr),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context), fontSize: 14)
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _categoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'food': icon = Icons.restaurant; color = AppTheme.colors.orangeAccent; break;
      case 'transport': icon = Icons.directions_car; color = AppTheme.colors.blueAccent; break;
      case 'tickets': icon = Icons.confirmation_number; color = AppTheme.colors.purpleAccent; break;
      default: icon = Icons.shopping_bag; color = AppTheme.colors.tealAccent;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
