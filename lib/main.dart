import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HasabatiApp());
}

class HasabatiApp extends StatelessWidget {
  const HasabatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حساباتي',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        fontFamily: 'sans',
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

String money(double value) {
  return NumberFormat('#,##0.##', 'en_US').format(value);
}

String nowText() => DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

String currencyName(String code) {
  switch (code) {
    case 'SAR':
      return 'ريال سعودي';
    case 'USD':
      return 'دولار أمريكي';
    default:
      return 'ريال يمني';
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  String search = '';

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onOpenCustomers: () => setState(() => index = 1)),
      CustomersPage(search: search),
      const ReportsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('حساباتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (index == 1)
            IconButton(
              tooltip: 'بحث',
              onPressed: () async {
                final q = await showSearch<String?>(
                  context: context,
                  delegate: CustomerSearchDelegate(),
                );
                if (q != null) setState(() => search = q);
              },
              icon: const Icon(Icons.search),
            ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'العملاء'),
          NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: 'التقارير'),
        ],
      ),
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _addCustomer(context),
              icon: const Icon(Icons.person_add),
              label: const Text('عميل جديد'),
            )
          : null,
    );
  }

  Future<void> _addCustomer(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const CustomerDialog(),
    );
    if (saved == true) setState(() {});
  }
}

class DashboardPage extends StatefulWidget {
  final VoidCallback onOpenCustomers;
  const DashboardPage({super.key, required this.onOpenCustomers});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<List<Map<String, dynamic>>> _data() =>
      AppDatabase.instance.customerBalances();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _data(),
        builder: (context, snap) {
          final rows = snap.data ?? [];
          double total = 0;
          for (final r in rows) total += (r['balance'] as num).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملخص الحسابات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('${rows.length}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                      const Text('عدد العملاء'),
                      const SizedBox(height: 12),
                      Text(money(total), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                      const Text('الرصيد الإجمالي المعروض'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _QuickButton(icon: Icons.person_add, text: 'إضافة عميل', onTap: widget.onOpenCustomers)),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickButton(icon: Icons.receipt_long, text: 'العمليات', onTap: widget.onOpenCustomers)),
                ],
              ),
              const SizedBox(height: 18),
              const Text('آخر العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا يوجد عملاء بعد'))))
              else
                ...rows.take(8).map((r) {
                  final bal = (r['balance'] as num).toDouble();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text((r['name'] as String).characters.first)),
                      title: Text(r['name'] as String),
                      subtitle: Text((r['phone'] ?? '') as String),
                      trailing: Text('${money(bal)} ${r['currency']}', style: TextStyle(fontWeight: FontWeight.bold, color: bal >= 0 ? Colors.green : Colors.red)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _QuickButton({required this.icon, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
      );
}

class CustomersPage extends StatefulWidget {
  final String search;
  const CustomersPage({super.key, this.search = ''});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late String search;

  @override
  void initState() {
    super.initState();
    search = widget.search;
  }

  @override
  void didUpdateWidget(covariant CustomersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    search = widget.search;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Customer>>(
      future: AppDatabase.instance.customers(query: search),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final customers = snap.data!;
        if (customers.isEmpty) {
          return const Center(child: Text('لا يوجد عملاء. أضف أول عميل من زر +'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: customers.length,
          itemBuilder: (_, i) {
            final c = customers[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(c.name.characters.first)),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text([c.phone, c.address].where((x) => x.isNotEmpty).join(' • ')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerPage(customer: c)));
                  setState(() {});
                },
                onLongPress: () => _edit(c),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _edit(Customer c) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => CustomerDialog(customer: c));
    if (saved == true) setState(() {});
  }
}

class CustomerSearchDelegate extends SearchDelegate<String?> {
  CustomerSearchDelegate() {
    searchFieldLabel = 'ابحث باسم العميل أو الهاتف';
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _result();
  @override
  Widget buildSuggestions(BuildContext context) => _result();

  Widget _result() {
    return FutureBuilder<List<Customer>>(
      future: AppDatabase.instance.customers(query: query),
      builder: (context, snap) {
        final data = snap.data ?? [];
        return ListView(
          children: data
              .map((c) => ListTile(title: Text(c.name), subtitle: Text(c.phone), onTap: () => close(context, query)))
              .toList(),
        );
      },
    );
  }
}

class CustomerDialog extends StatefulWidget {
  final Customer? customer;
  const CustomerDialog({super.key, this.customer});
  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController address;
  late final TextEditingController note;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    name = TextEditingController(text: c?.name ?? '');
    phone = TextEditingController(text: c?.phone ?? '');
    address = TextEditingController(text: c?.address ?? '');
    note = TextEditingController(text: c?.note ?? '');
  }

  @override
  void dispose() {
    name.dispose(); phone.dispose(); address.dispose(); note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.customer == null ? 'إضافة عميل' : 'تعديل العميل'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم العميل'), validator: (v) => v!.trim().isEmpty ? 'أدخل اسم العميل' : null),
                const SizedBox(height: 10),
                TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                const SizedBox(height: 10),
                TextFormField(controller: address, decoration: const InputDecoration(labelText: 'العنوان')),
                const SizedBox(height: 10),
                TextFormField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظة')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: _save, child: const Text('حفظ')),
        ],
      );

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final old = widget.customer;
    final c = Customer(
      id: old?.id,
      name: name.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      note: note.text.trim(),
      createdAt: old?.createdAt ?? nowText(),
    );
    if (old == null) {
      await AppDatabase.instance.insertCustomer(c);
    } else {
      await AppDatabase.instance.updateCustomer(c);
    }
    if (mounted) Navigator.pop(context, true);
  }
}

class CustomerPage extends StatefulWidget {
  final Customer customer;
  const CustomerPage({super.key, required this.customer});
  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  Future<List<Entry>> _entries() => AppDatabase.instance.entriesForCustomer(widget.customer.id!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملية'),
      ),
      body: FutureBuilder<List<Entry>>(
        future: _entries(),
        builder: (context, snap) {
          final entries = snap.data ?? [];
          final balances = <String, double>{};
          for (final e in entries) {
            final sign = e.type == EntryType.credit ? 1 : -1;
            balances[e.currency] = (balances[e.currency] ?? 0) + sign * e.amount;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.customer.phone.isNotEmpty) Text('الهاتف: ${widget.customer.phone}'),
                      if (widget.customer.address.isNotEmpty) Text('العنوان: ${widget.customer.address}'),
                      if (widget.customer.note.isNotEmpty) Text('ملاحظة: ${widget.customer.note}'),
                      const Divider(),
                      ...balances.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(currencyName(e.key)),
                                Text('${money(e.value)} ${e.key}', style: TextStyle(fontWeight: FontWeight.bold, color: e.value >= 0 ? Colors.green : Colors.red)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد عمليات لهذا العميل'))))
              else
                ...entries.map((e) => _entryCard(e)),
            ],
          );
        },
      ),
    );
  }

  Widget _entryCard(Entry e) {
    final positive = e.type == EntryType.credit;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward),
        ),
        title: Text('${e.type.label} • ${money(e.amount)} ${e.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${e.description.isEmpty ? 'بدون بيان' : e.description}\n${e.date}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'share') {
              await Share.share(_shareText(e));
            } else if (v == 'delete') {
              await AppDatabase.instance.deleteEntry(e.id!);
              setState(() {});
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'share', child: Text('مشاركة')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  String _shareText(Entry e) {
    return 'حساباتي\n'
        'العميل: ${widget.customer.name}\n'
        'العملية: ${e.type.label}\n'
        'المبلغ: ${money(e.amount)} ${e.currency}\n'
        'البيان: ${e.description.isEmpty ? 'بدون بيان' : e.description}\n'
        'التاريخ: ${e.date}';
  }

  Future<void> _addEntry() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EntryDialog(customerId: widget.customer.id!),
    );
    if (saved == true) setState(() {});
  }

  Future<void> _edit() async {
    final saved = await showDialog<bool>(context: context, builder: (_) => CustomerDialog(customer: widget.customer));
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text('سيتم حذف العميل وجميع عملياته. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.deleteCustomer(widget.customer.id!);
      if (mounted) Navigator.pop(context);
    }
  }
}

class EntryDialog extends StatefulWidget {
  final int customerId;
  const EntryDialog({super.key, required this.customerId});
  @override
  State<EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<EntryDialog> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final description = TextEditingController();
  EntryType type = EntryType.credit;
  String currency = 'YER';

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة عملية'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<EntryType>(
                  segments: const [
                    ButtonSegment(value: EntryType.credit, label: Text('له'), icon: Icon(Icons.arrow_downward)),
                    ButtonSegment(value: EntryType.debit, label: Text('عليه'), icon: Icon(Icons.arrow_upward)),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (v) {
                    final n = double.tryParse(v!.trim());
                    return n == null || n <= 0 ? 'أدخل مبلغاً صحيحاً' : null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: const InputDecoration(labelText: 'العملة'),
                  items: const [
                    DropdownMenuItem(value: 'YER', child: Text('ريال يمني YER')),
                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي SAR')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي USD')),
                  ],
                  onChanged: (v) => setState(() => currency = v!),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'البيان / الملاحظة')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: _save, child: const Text('حفظ')),
        ],
      );

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    await AppDatabase.instance.insertEntry(Entry(
      customerId: widget.customerId,
      type: type,
      amount: double.parse(amount.text.trim()),
      currency: currency,
      description: description.text.trim(),
      date: nowText(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppDatabase.instance.customerBalances(),
      builder: (context, snap) {
        final rows = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('تقرير العملاء', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('إجمالي العملاء: ${rows.length}', style: const TextStyle(fontSize: 17)),
              ),
            ),
            ...rows.map((r) {
              final b = (r['balance'] as num).toDouble();
              return Card(
                child: ListTile(
                  title: Text(r['name'] as String),
                  subtitle: Text('${r['currency']} • ${r['phone'] ?? ''}'),
                  trailing: Text(money(b), style: TextStyle(fontWeight: FontWeight.bold, color: b >= 0 ? Colors.green : Colors.red)),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
