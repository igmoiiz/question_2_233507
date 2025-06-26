// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controller/input_controllers.dart';
import '../model/expense.dart';

class InterfacePage extends StatelessWidget {
  const InterfacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseController()..loadExpenses(),
      child: ExpenseHome(),
    );
  }
}

class ExpenseHome extends StatefulWidget {
  const ExpenseHome({super.key});

  @override
  State<ExpenseHome> createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome> {
  int _selectedIndex = 0;
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ExpenseController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _dashboard(context, controller),
          _expenseList(context, controller),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 1
              ? FloatingActionButton(
                onPressed: () => _showAddEditDialog(context, controller),
                child: Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _dashboard(BuildContext context, ExpenseController controller) {
    final total = controller.totalMonthlyExpense;
    final recent = controller.recentTransactions;
    final Map<String, double> categoryTotals = {};
    for (var e in controller.expenses) {
      if (e.date.month == DateTime.now().month &&
          e.date.year == DateTime.now().year) {
        categoryTotals[e.category] =
            (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            elevation: 4,
            child: ListTile(
              leading: Icon(Icons.account_balance_wallet, size: 40),
              title: Text('Total This Month'),
              subtitle: Text('Rs. 	${total.toStringAsFixed(2)}'),
              trailing:
                  total > 10000
                      ? Chip(
                        label: Text('High!'),
                        backgroundColor: Colors.redAccent,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                      : null,
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses by Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 200, child: _buildPieChart(categoryTotals)),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Recent Transactions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...recent
              .map((e) => _expenseCard(context, e, controller, animated: false))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) return Center(child: Text('No data'));
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    int i = 0;
    return PieChart(
      PieChartData(
        sections:
            data.entries.map((e) {
              final color = colors[i++ % colors.length];
              return PieChartSectionData(
                color: color,
                value: e.value,
                title: e.key,
                radius: 50,
                titleStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _expenseList(BuildContext context, ExpenseController controller) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: controller.expenses.length,
      itemBuilder: (context, i) {
        final e = controller.expenses[i];
        return _expenseCard(context, e, controller, animated: true);
      },
    );
  }

  Widget _expenseCard(
    BuildContext context,
    Expense e,
    ExpenseController controller, {
    bool animated = true,
  }) {
    final isHigh = e.amount > 2000;
    final card = Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.category),
        title: Text(e.title),
        subtitle: Text('${e.category} • ${DateFormat.yMMMd().format(e.date)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs. 	${e.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isHigh)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.warning, color: Colors.red),
              ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed:
                  () => _showAddEditDialog(context, controller, expense: e),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, controller, e),
            ),
          ],
        ),
      ),
    );
    return animated
        ? TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 500),
          builder:
              (context, value, child) =>
                  Transform.scale(scale: value, child: child),
          child: card,
        )
        : card;
  }

  void _showAddEditDialog(
    BuildContext context,
    ExpenseController controller, {
    Expense? expense,
  }) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(
      text: expense?.amount?.toString() ?? '',
    );
    String category = expense?.category ?? _categories.first;
    DateTime date = expense?.date ?? DateTime.now();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        icon: Icon(Icons.title),
                      ),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Enter title' : null,
                    ),
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        icon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || double.tryParse(v) == null
                                  ? 'Enter valid amount'
                                  : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: category,
                      items:
                          _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (v) => category = v!,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        icon: Icon(Icons.category),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.date_range),
                        SizedBox(width: 16),
                        Expanded(child: Text(DateFormat.yMMMd().format(date))),
                        TextButton(
                          child: Text('Pick'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              date = picked;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text(expense == null ? 'Add' : 'Update'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newExpense = Expense(
                      id: expense?.id,
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      category: category,
                      date: date,
                    );
                    if (expense == null) {
                      await controller.addExpense(newExpense);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expense added!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      await controller.updateExpense(newExpense);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expense updated!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ExpenseController controller,
    Expense e,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Expense?'),
            content: Text('Are you sure you want to delete this expense?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.deleteExpense(e.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Expense deleted!'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: Colors.white,
                        onPressed: () async {
                          await controller.addExpense(e);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showSearchDialog(BuildContext context, ExpenseController controller) {
    String? selectedCategory;
    DateTime? startDate;
    DateTime? endDate;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Search/Filter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items:
                      [null, ..._categories]
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c ?? 'All'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => selectedCategory = v,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        startDate == null
                            ? 'Start Date'
                            : DateFormat.yMMMd().format(startDate!),
                      ),
                    ),
                    TextButton(
                      child: Text('Pick'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          startDate = picked;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endDate == null
                            ? 'End Date'
                            : DateFormat.yMMMd().format(endDate!),
                      ),
                    ),
                    TextButton(
                      child: Text('Pick'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          endDate = picked;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Clear'),
                onPressed: () async {
                  await controller.loadExpenses();
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                child: Text('Search'),
                onPressed: () async {
                  await controller.searchExpenses(
                    category: selectedCategory,
                    start: startDate,
                    end: endDate,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }
}
