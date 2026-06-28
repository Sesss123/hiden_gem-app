import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trip_plan_model.dart';
import '../../data/datasources/trip_cache_service.dart';

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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                "DOCUMENT EXPENSE",
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2, 
                  color: AppTheme.textSecondary(context),
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
                      
                      setState(() {
                        widget.plan.realizedExpenses.add(newExpense);
                      });

                      if (widget.planId != null) {
                        await TripCacheService.updateSavedPlan(widget.planId!, widget.plan);
                      } else if (widget.cacheKey != null) {
                        await TripCacheService.cacheLastPlan(widget.plan, widget.cacheKey!);
                      }

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    "SAVE RECORD",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
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
        dropdownColor: Colors.white,
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
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: AppTheme.secondaryBorder(context))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "BUDGET TRACKER",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppTheme.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary), 
            onPressed: _addExpense
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.secondaryBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160, height: 160,
                        child: CircularProgressIndicator(
                          value: _percentUsed,
                          strokeWidth: 4,
                          backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                          color: isOverBudget ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "${(_percentUsed * 100).toInt()}%", 
                            style: GoogleFonts.outfit(
                              fontSize: 32, 
                              fontWeight: FontWeight.w900, 
                              color: isOverBudget ? Colors.redAccent : AppTheme.textPrimary(context),
                              letterSpacing: -1,
                            )
                          ),
                          Text(
                            "USED", 
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary(context), 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 2
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem("PLAN LIMIT", _currencyFormat.format(_budget), AppTheme.textSecondary(context)),
                      _statItem("CURRENT CONSUMPTION", _currencyFormat.format(_totalSpent), isOverBudget ? Colors.redAccent : Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "EXPENSE LEDGER",
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2, 
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                Text(
                  "${widget.plan.realizedExpenses.length} ENTRIES", 
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
            const SizedBox(height: 24),

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
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary(context).withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            "NO ENTRIES DISCOVERED", 
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _addExpense, 
            child: Text(
              "SYNC FIRST ENTRY", 
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _categoryIcon(e.category),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title.toUpperCase(), 
                  style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, HH:mm').format(e.timestamp), 
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(e.amountLkr), 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context), fontSize: 16, letterSpacing: -0.5)
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _categoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'food': icon = Icons.restaurant; color = Colors.orangeAccent; break;
      case 'transport': icon = Icons.directions_car; color = Colors.blueAccent; break;
      case 'tickets': icon = Icons.confirmation_number; color = Colors.purpleAccent; break;
      default: icon = Icons.shopping_bag; color = Colors.tealAccent;
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
