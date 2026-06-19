import 'package:equatable/equatable.dart';

enum ExpenseCategory { food, transport, attraction, lodging, shopping, other }

class Expense extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    this.currency = 'LKR',
    required this.category,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'LKR',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.toString().split('.').last,
      'date': date.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, description, amount, category, date];
}
