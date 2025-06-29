// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../controller/input_controllers.dart';
import '../model/expense.dart';

class InterfacePage extends StatelessWidget {
  const InterfacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseController()..loadExpenses(),
      child: const ExpenseHome(),
    );
  }
}

class ExpenseHome extends StatefulWidget {
  const ExpenseHome({super.key});

  @override
  State<ExpenseHome> createState() => _ExpenseHomeState();
}

class _ExpenseHomeState extends State<ExpenseHome>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ExpenseController>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _selectedIndex = i);
        },
        children: [
          _dashboard(context, controller),
          _expenseList(context, controller),
          _analyticsPage(context, controller),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: GNav(
            gap: 8,
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: Colors.white70,
            activeColor: Theme.of(context).colorScheme.primary,
            tabBackgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            selectedIndex: _selectedIndex,
            onTabChange: (i) {
              if (_selectedIndex != i) {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            tabs: const [
              GButton(icon: Icons.dashboard, text: 'Dashboard'),
              GButton(icon: Icons.list, text: 'Expenses'),
              GButton(icon: Icons.analytics, text: 'Analytics'),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _selectedIndex == 1
              ? FloatingActionButton(
                onPressed: () => _showAddEditDialog(context, controller),
                child: const Icon(Icons.add),
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
    final List<Color> pieColors = [
      const Color(0xFF00B894),
      const Color(0xFF00CEC9),
      const Color(0xFF0984E3),
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFFFF7675),
    ];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, size: 40),
              title: const Text(
                'Total This Month',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Rs.  ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing:
                  total > 10000
                      ? Chip(
                        label: const Text('High!'),
                        backgroundColor: Colors.redAccent,
                        labelStyle: const TextStyle(color: Colors.white),
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expenses by Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _buildPieChart(categoryTotals, pieColors),
                  ),
                  const SizedBox(height: 12),
                  _buildPieLegend(categoryTotals, pieColors),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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

  Widget _buildPieChart(Map<String, double> data, List<Color> colors) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    int i = 0;
    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections:
            data.entries.map((e) {
              final color = colors[i % colors.length];
              final value = e.value;
              final percent =
                  data.values.fold(0.0, (a, b) => a + b) == 0
                      ? 0
                      : (value / data.values.fold(0.0, (a, b) => a + b)) * 100;
              i++;
              return PieChartSectionData(
                color: color,
                value: value,
                title: percent < 8 ? '' : '${percent.toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                badgeWidget: percent >= 8 ? null : const SizedBox.shrink(),
                badgePositionPercentageOffset: .98,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPieLegend(Map<String, double> data, List<Color> colors) {
    if (data.isEmpty) return const SizedBox.shrink();
    int i = 0;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children:
          data.keys.map((cat) {
            final color = colors[i % colors.length];
            i++;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(cat, style: const TextStyle(color: Colors.white70)),
              ],
            );
          }).toList(),
    );
  }

  Widget _expenseList(BuildContext context, ExpenseController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.expenses.length,
      itemBuilder: (context, i) {
        final e = controller.expenses[i];
        return _expenseCard(context, e, controller, animated: true, index: i);
      },
    );
  }

  Widget _expenseCard(
    BuildContext context,
    Expense e,
    ExpenseController controller, {
    bool animated = true,
    int index = 0,
  }) {
    final isHigh = e.amount > 2000;
    final card = Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor.withOpacity(0.95),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.8),
          child: Icon(Icons.category, color: Colors.white),
        ),
        title: Text(
          e.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${e.category} • ${DateFormat.yMMMd().format(e.date)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs. ${e.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (isHigh)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.warning, color: Colors.redAccent.shade100),
              ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed:
                  () => _showAddEditDialog(context, controller, expense: e),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: () => _confirmDelete(context, controller, e),
            ),
          ],
        ),
      ),
    );
    return animated
        ? SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset(0, 0),
          ).animate(
            CurvedAnimation(
              parent: AnimationController(
                vsync: this,
                duration: Duration(milliseconds: 400 + (index * 40)),
              )..forward(),
              curve: Curves.easeOutCubic,
            ),
          ),
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
      text: expense?.amount.toString() ?? '',
    );
    String category = expense?.category ?? _categories.first;
    DateTime date = expense?.date ?? DateTime.now();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add/Edit Expense',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder:
          (context, anim1, anim2) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expense == null ? 'Add Expense' : 'Edit Expense',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            icon: Icon(Icons.title),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Enter title' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: category,
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => category = v!,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            icon: Icon(Icons.category),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.date_range),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                DateFormat.yMMMd().format(date),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              child: const Text('Pick'),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: Color(0xFF00B894),
                                          surface: Color(0xFF393E46),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  date = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                                      const SnackBar(
                                        content: Text('Expense added!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    await controller.updateExpense(newExpense);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ExpenseController controller,
    Expense e,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Expense',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder:
          (context, anim1, anim2) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Delete Expense?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Are you sure you want to delete this expense?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Delete'),
                          onPressed: () async {
                            Navigator.pop(context);
                            await controller.deleteExpense(e.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Expense deleted!'),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context, ExpenseController controller) {
    String? selectedCategory;
    DateTime? startDate;
    DateTime? endDate;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search/Filter',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder:
          (context, anim1, anim2) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Search/Filter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            startDate == null
                                ? 'Start Date'
                                : DateFormat.yMMMd().format(startDate!),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          child: const Text('Pick'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFF00B894),
                                      surface: Color(0xFF393E46),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              startDate = picked;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            endDate == null
                                ? 'End Date'
                                : DateFormat.yMMMd().format(endDate!),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          child: const Text('Pick'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFF00B894),
                                      surface: Color(0xFF393E46),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              endDate = picked;
                              (context as Element).markNeedsBuild();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Clear'),
                          onPressed: () async {
                            await controller.loadExpenses();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Search'),
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
                  ],
                ),
              ),
            ),
          ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  Widget _analyticsPage(BuildContext context, ExpenseController controller) {
    final expenses = controller.expenses;
    if (expenses.isEmpty) {
      return const Center(child: Text('No data to analyze'));
    }
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final gridColor = Colors.white10;
    final borderColor = Colors.white24;
    // Pie chart data
    final Map<String, double> categoryTotals = {};
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final List<Color> pieColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      const Color(0xFF0984E3),
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFFFF7675),
    ];
    // Line chart data (expenses over time)
    final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
    final Map<String, double> dateTotals = {};
    for (var e in sorted) {
      final key = DateFormat('MM/dd').format(e.date);
      dateTotals[key] = (dateTotals[key] ?? 0) + e.amount;
    }
    final lineSpots =
        dateTotals.entries.toList().asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();
    final lineLabels = dateTotals.keys.toList();
    // Bar chart data (category totals)
    final barGroups =
        categoryTotals.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final value = entry.value.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: value,
                gradient: LinearGradient(
                  colors: [
                    pieColors[idx % pieColors.length],
                    pieColors[(idx + 1) % pieColors.length],
                  ],
                ),
                width: 22,
                borderRadius: BorderRadius.circular(8),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 0,
                  color: cardColor.withOpacity(0.7),
                ),
                rodStackItems: [],
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList();
    final barLabels = categoryTotals.keys.toList();
    // Analytics summary
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final highest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final lowest = expenses.reduce((a, b) => a.amount < b.amount ? a : b);
    final avg = total / expenses.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 12,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Expense Distribution',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sections:
                          categoryTotals.entries.map((e) {
                            final idx = categoryTotals.keys.toList().indexOf(
                              e.key,
                            );
                            final color = pieColors[idx % pieColors.length];
                            final value = e.value;
                            final percent =
                                categoryTotals.values.fold(
                                          0.0,
                                          (a, b) => a + b,
                                        ) ==
                                        0
                                    ? 0
                                    : (value /
                                            categoryTotals.values.fold(
                                              0.0,
                                              (a, b) => a + b,
                                            )) *
                                        100;
                            return PieChartSectionData(
                              color: color,
                              value: value,
                              title:
                                  percent < 8
                                      ? ''
                                      : '${percent.toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            );
                          }).toList(),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPieLegend(categoryTotals, pieColors),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 12,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: const Color(0xFF0984E3)),
                    const SizedBox(width: 8),
                    Text(
                      'Expenses Over Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      backgroundColor: cardColor,
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'Rs. ${value.toInt()}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < lineLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    lineLabels[idx],
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine:
                            (value) => FlLine(color: gridColor, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: borderColor),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: cardColor,
                          getTooltipItems:
                              (touchedSpots) =>
                                  touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'Rs. ${spot.y.toStringAsFixed(2)}',
                                      TextStyle(
                                        color: theme.colorScheme.primary,
                                      ),
                                    );
                                  }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 12,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: const Color(0xFF6C5CE7)),
                    const SizedBox(width: 8),
                    Text(
                      'Category Totals',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      backgroundColor: cardColor,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'Rs. ${value.toInt()}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < barLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    barLabels[idx],
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine:
                            (value) => FlLine(color: gridColor, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: borderColor),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: cardColor,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Rs. ${rod.toY.toStringAsFixed(2)}',
                              TextStyle(color: theme.colorScheme.primary),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 12,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Analytics Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.savings, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Total Expenses: Rs. ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF0984E3)),
                    const SizedBox(width: 8),
                    Text(
                      'Average Expense: Rs. ${avg.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Highest: ${highest.title} (Rs. ${highest.amount.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Lowest: ${lowest.title} (Rs. ${lowest.amount.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Color(0xFF6C5CE7)),
                    const SizedBox(width: 8),
                    Text(
                      'Transactions: ${expenses.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
