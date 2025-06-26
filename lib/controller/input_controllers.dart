import 'package:flutter/material.dart';
import 'services/expense_db.dart';
import '../model/expense.dart';

class ExpenseController extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  double get totalMonthlyExpense {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> get recentTransactions => _expenses.take(5).toList();

  Future<void> loadExpenses() async {
    _expenses = await ExpenseDatabase.instance.getAllExpenses();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await ExpenseDatabase.instance.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await ExpenseDatabase.instance.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await ExpenseDatabase.instance.deleteExpense(id);
    await loadExpenses();
  }

  Future<void> searchExpenses({
    String? category,
    DateTime? start,
    DateTime? end,
  }) async {
    _expenses = await ExpenseDatabase.instance.searchExpenses(
      category: category,
      start: start,
      end: end,
    );
    notifyListeners();
  }
}
