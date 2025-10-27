import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // We'll use a simple box storing maps for each expense keyed by id.
  await Hive.openBox('expenses');
  runApp(const ExpenseApp());
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({required this.id, required this.title, required this.amount, required this.category, DateTime? date}) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  static Expense fromMap(Map m) => Expense(
        id: m['id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] is num) ? (m['amount'] as num).toDouble() : double.tryParse('${m['amount']}') ?? 0.0,
        category: m['category'] as String,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ExpenseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final box = Hive.box('expenses');
  final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other'];

  List<Expense> get _expenses {
    return box.keys.map((k) {
      final v = box.get(k);
      if (v is Map) return Expense.fromMap(v);
      if (v is String) return Expense.fromMap(Map.castFrom<dynamic, dynamic, String, dynamic>(v as Map));
      return Expense(id: '$k', title: '$v', amount: 0, category: 'Other');
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _addExpense() async {
    final result = await showDialog<Expense?>(context: context, builder: (c) => AddExpenseDialog(categories: categories));
    if (result == null) return;
    await box.put(result.id, result.toMap());
    setState(() {});
  }

  void _deleteExpense(String id) async {
    await box.delete(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
  }

  Map<String, double> _summarizeByCategory() {
    final map = <String, double>{};
    for (final c in categories) map[c] = 0.0;
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _expenses;
    final summary = _summarizeByCategory();
    final nonZero = summary.entries.where((e) => e.value > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: Column(
        children: [
          // Chart area
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: nonZero.isEmpty
                      ? const Center(child: Text('No expenses yet'))
                      : PieChart(
                          PieChartData(
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: nonZero
                                .map((e) {
                                  final idx = nonZero.indexOf(e);
                                  final color = Colors.primaries[idx % Colors.primaries.length];
                                  return PieChartSectionData(
                                    value: e.value,
                                    color: color.shade400,
                                    title: '${(e.value).toStringAsFixed(0)}',
                                    radius: 50,
                                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // List area
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('No expenses recorded. Tap + to add one.'))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final e = expenses[index];
                      return Dismissible(
                        key: Key(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteExpense(e.id),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(e.category[0])),
                          title: Text(e.title),
                          subtitle: Text('${e.category} • ${e.date.toLocal().toString().split(' ')[0]}'),
                          trailing: Text('\$${e.amount.toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final List<String> categories;
  const AddExpenseDialog({super.key, required this.categories});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Other';

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) _category = widget.categories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (title.isEmpty || amount <= 0) return;
    final e = Expense(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, amount: amount, category: _category);
    Navigator.of(context).pop(e);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? widget.categories.first),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
