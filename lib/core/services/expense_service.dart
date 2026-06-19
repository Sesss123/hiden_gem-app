import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/expense_model.dart';
import '../utils/secure_logger.dart';

class ExpenseService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'user_expenses_log';

  static Future<List<Expense>> getExpenses() async {
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr == null) return [];
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      SecureLogger.error('Failed to read expenses: $e');
      return [];
    }
  }

  static Future<void> addExpense(Expense expense) async {
    try {
      final expenses = await getExpenses();
      expenses.add(expense);
      await _storage.write(key: _key, value: json.encode(expenses.map((e) => e.toJson()).toList()));
    } catch (e) {
      SecureLogger.error('Failed to add expense: $e');
    }
  }

  static Future<double> getTotalSpent() async {
    final expenses = await getExpenses();
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  static Future<Map<ExpenseCategory, double>> getSpendingByCategory() async {
    final expenses = await getExpenses();
    final Map<ExpenseCategory, double> breakdown = {};
    for (var e in expenses) {
      breakdown[e.category] = (breakdown[e.category] ?? 0.0) + e.amount;
    }
    return breakdown;
  }
}
