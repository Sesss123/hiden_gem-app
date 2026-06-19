import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
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
          builder: (context, setModalState) => OracleUI.glassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.15),
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
              SizedBox(height: 32),
              OracleUI.neonText(
                "DOCUMENT EXPENSE",
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2, 
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
              SizedBox(height: 32),
              _buildModernInput("Resource Description", (v) => title = v),
              SizedBox(height: 20),
              _buildModernInput("Amount (LKR)", (v) => amount = int.tryParse(v) ?? 0, isNumber: true),
              SizedBox(height: 20),
              _buildModernDropdown(category, (v) => setModalState(() => category = v!)),
              SizedBox(height: 48),
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
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: OracleUI.neonText(
                    "SYNC TO VAULT",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5),
                    glowColor: Colors.black26,
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
    return OracleUI.glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      borderRadius: BorderRadius.circular(16),
      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
    return OracleUI.glassContainer(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      borderRadius: BorderRadius.circular(16),
      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: DropdownButtonFormField<String>(
        value: current,
        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: OracleUI.neonText(
          "BUDGET VAULT",
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
          SizedBox(width: 8),
        ],
      ),
      body: OracleUI.auraBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(28),
        child: Column(
          children: [
            // Visualization Card
            OracleUI.glassContainer(
              padding: EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(32),
              borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                            "EXHAUSTED", 
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary(context).withValues(alpha: 0.6), 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 2
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 48),
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

            SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OracleUI.neonText(
                  "EXPENSE LEDGER",
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2, 
                    color: AppTheme.textPrimary(context)
                  ),
                ),
                Text(
                  "${widget.plan.realizedExpenses.length} ENTRIES", 
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
            SizedBox(height: 24),

            if (widget.plan.realizedExpenses.isEmpty)
              _buildEmptyState()
            else
              ...widget.plan.realizedExpenses.reversed.map((e) => _buildExpenseItem(e)),
          ],
        ),
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
    return OracleUI.glassContainer(
      width: double.infinity,
      padding: EdgeInsets.all(48),
      borderRadius: BorderRadius.circular(32),
      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textSecondary(context).withValues(alpha: 0.3)),
          SizedBox(height: 24),
          Text(
            "NO ENTRIES DISCOVERED", 
            style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
          SizedBox(height: 24),
          TextButton(
            onPressed: _addExpense, 
            child: OracleUI.neonText(
              "SYNC FIRST ENTRY", 
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
              glowColor: Theme.of(context).colorScheme.primary,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense e) {
    return OracleUI.glassContainer(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          _categoryIcon(e.category),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title.toUpperCase(), 
                  style: GoogleFonts.inter(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, HH:mm').format(e.timestamp), 
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
          ),
          OracleUI.neonText(
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
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(10),
      borderColor: color.withValues(alpha: 0.1),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
