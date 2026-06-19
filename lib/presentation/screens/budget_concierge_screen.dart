import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../core/services/expense_service.dart';
import '../../data/models/expense_model.dart';
import '../../core/config/app_config.dart';

class BudgetConciergeScreen extends ConsumerStatefulWidget {
  const BudgetConciergeScreen({super.key});

  @override
  ConsumerState<BudgetConciergeScreen> createState() => _BudgetConciergeScreenState();
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
    if (AppConfig.geminiApiKey.isEmpty) return;

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: AppConfig.geminiApiKey);
      final prompt = """
        You are 'Oracle Budget Concierge' for a traveler in Sri Lanka.
        The user has spent total $_totalSpent LKR so far.
        Expenses: ${_expenses.map((e) => "${e.description}: ${e.amount}").join(", ")}
        
        Provide a short (2 sentence) cinematic advice on their budget. 
        Focus on value-for-money transport (like using PickMe/Uber vs private tours) 
        and suggest maintaining a sustainable pace.
      """;
      final response = await model.generateContent([Content.text(prompt)]);
      if (mounted) {
        setState(() => _aiAdvice = response.text ?? "Your gold is safe, traveler.");
      }
    } catch (e) {
      if (mounted) setState(() => _aiAdvice = "The Oracle is silent on your gold for now.");
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
                            Text("RECENT TRANSACTIONS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.secondary),
                              onPressed: _showAddExpenseDialog,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        ..._expenses.reversed.toList().asMap().entries.map((entry) => _buildExpenseTile(entry.value, entry.key)),
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
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          OracleUI.neonText(
            "BUDGET CONCIERGE",
            style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w900,
              letterSpacing: 4, fontSize: 16,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(40),
      borderRadius: BorderRadius.circular(32),
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Column(
        children: [
          Text(
            "TOTAL MANIFESTED", 
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)
          ),
          SizedBox(height: 12),
          OracleUI.neonText(
            "Rs. ${_totalSpent.toStringAsFixed(0)}",
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          SizedBox(height: 8),
          Text(
            "≈ \$${(_totalSpent / 320).toStringAsFixed(2)} USD", 
            style: GoogleFonts.inter(color: Colors.white10, fontSize: 12, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAIAdviceCard() {
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary, size: 28)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 3.seconds),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OracleUI.neonText(
                  "ADVICE FROM THE ORACLE",
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                Text(
                  _aiAdvice,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildExpenseTile(Expense e, int index) {
    return OracleUI.glassContainer(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: [
          _categoryIcon(e.category),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.description.toUpperCase(), 
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)
                ),
                SizedBox(height: 4),
                Text(
                  e.date.toString().split(' ')[0], 
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          OracleUI.neonText(
            "Rs. ${e.amount.toInt()}", 
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)
          ),
        ],
      ),
    ).animate().fadeIn(delay: (400 + (index * 100)).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _categoryIcon(ExpenseCategory cat) {
    IconData icon = Icons.receipt_long_rounded;
    Color color = Colors.white24;
    switch(cat) {
      case ExpenseCategory.food: icon = Icons.restaurant_rounded; color = Colors.orangeAccent; break;
      case ExpenseCategory.transport: icon = Icons.directions_car_rounded; color = Colors.blueAccent; break;
      case ExpenseCategory.attraction: icon = Icons.temple_buddhist_rounded; color = Theme.of(context).colorScheme.primary; break;
      case ExpenseCategory.lodging: icon = Icons.hotel_rounded; color = Colors.purpleAccent; break;
      default: icon = Icons.more_horiz_rounded; color = Colors.grey;
    }
    return OracleUI.glassContainer(
      padding: EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(12),
      borderColor: color.withValues(alpha: 0.2),
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
      backgroundColor: Colors.transparent,
      builder: (context) => OracleUI.glassContainer(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 40, top: 24, left: 24, right: 24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 32),
            OracleUI.neonText("LOG TRANSACTION", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16)),
            SizedBox(height: 48),
            TextField(
              controller: descController,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "WHAT WAS THE PURPOSE?",
                hintStyle: GoogleFonts.inter(color: Colors.white12, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 10),
                prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              decoration: InputDecoration(
                hintText: "AMOUNT (LKR)",
                hintStyle: GoogleFonts.inter(color: Colors.white12, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 10),
                prefixIcon: Icon(Icons.payments_rounded, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0 && descController.text.isNotEmpty) {
                    final expense = Expense(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description: descController.text,
                      amount: amount,
                      category: selectedCat,
                      date: DateTime.now(),
                    );
                    await ExpenseService.addExpense(expense);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: OracleUI.neonText(
                  "SAVE TO ARCHIVES",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                  glowColor: Colors.black12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
