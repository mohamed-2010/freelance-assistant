import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const InvoiceCreateScreen({super.key, this.clientId});

  @override
  ConsumerState<InvoiceCreateScreen> createState() =>
      _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  String? _selectedClientId;
  final Set<String> _selectedTaskIds = {};
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final allTasks = ref.watch(allTasksProvider);
    final projects = ref.watch(allProjectsProvider);
    final invoices = ref.watch(allInvoicesProvider);
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat('#,##0', 'en');

    // Get invoiced task IDs
    final invoicedTaskIds = <String>{};
    for (final inv in invoices) {
      if (inv.status != 'cancelled') {
        invoicedTaskIds.addAll(inv.taskIds);
      }
    }

    // Tasks for selected client (via project) — not already invoiced
    final clientProjectIds = _selectedClientId != null
        ? projects
            .where((p) => p.clientId == _selectedClientId)
            .map((p) => p.id)
            .toSet()
        : <String>{};

    final availableTasks = allTasks.where((t) {
      return clientProjectIds.contains(t.projectId) &&
          !invoicedTaskIds.contains(t.id) &&
          t.cost > 0;
    }).toList();

    final subtotal = _selectedTaskIds
        .map((id) => allTasks.firstWhere((t) => t.id == id).cost)
        .fold(0.0, (sum, cost) => sum + cost);

    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء فاتورة'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Client selector
          DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: const InputDecoration(
              labelText: 'العميل *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: clients
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedClientId = v;
              _selectedTaskIds.clear();
            }),
          ),
          const SizedBox(height: 24),

          // Tasks to include
          Text('اختار الأعمال:',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (availableTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedClientId == null
                          ? 'اختار عميل أولاً'
                          : 'لا توجد أعمال جاهزة للفوترة',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...availableTasks.map((task) {
              final project = projects.firstWhere(
                (p) => p.id == task.projectId,
                orElse: () => projects.first,
              );
              final isSelected = _selectedTaskIds.contains(task.id);
              return Card(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15)
                    : null,
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedTaskIds.add(task.id);
                      } else {
                        _selectedTaskIds.remove(task.id);
                      }
                    });
                  },
                  title: Text(task.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${project.name} • ${fmt.format(task.cost)} $currency',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  secondary: Text(
                    '${fmt.format(task.cost)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        fontSize: 16),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Discount
          TextFormField(
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'خصم',
              prefixIcon: const Icon(Icons.discount_outlined),
              suffixText: currency,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 24),

          // Summary card
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _summaryRow('المجموع', fmt.format(subtotal), currency),
                  if (discount > 0) ...[
                    const Divider(),
                    _summaryRow('الخصم', '- ${fmt.format(discount)}', currency),
                  ],
                  const Divider(thickness: 2),
                  _summaryRow('الإجمالي', fmt.format(total), currency,
                      bold: true, color: Colors.amberAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _selectedTaskIds.isEmpty ? null : () => _save(false),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ كمسودة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _selectedTaskIds.isEmpty ? null : () => _save(true),
                  icon: const Icon(Icons.share),
                  label: const Text('حفظ وإرسال'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, String currency,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 18 : 14)),
          Text('$value $currency',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 18 : 14,
                  color: color)),
        ],
      ),
    );
  }

  void _save(bool share) {
    final allTasks = ref.read(allTasksProvider);
    final subtotal = _selectedTaskIds
        .map((id) => allTasks.firstWhere((t) => t.id == id).cost)
        .fold(0.0, (sum, cost) => sum + cost);
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    ref.read(allInvoicesProvider.notifier).add(
          clientId: _selectedClientId!,
          taskIds: _selectedTaskIds.toList(),
          subtotal: subtotal,
          discount: discount,
          notes: _notesController.text,
        );

    if (share) {
      final client = ref
          .read(clientsProvider)
          .firstWhere((c) => c.id == _selectedClientId);
      final total = subtotal - discount;
      final fmt = NumberFormat('#,##0', 'en');
      final currency = ref.read(currencyProvider);
      final invoice = ref.read(allInvoicesProvider).last;

      final text = '''
📄 فاتورة رقم #${invoice.invoiceNumber}
👤 العميل: ${client.name}
📅 التاريخ: ${DateFormat('yyyy/MM/dd').format(invoice.issuedAt)}

━━━━━━━━━━━━━━━━
${_selectedTaskIds.map((id) {
        final t = allTasks.firstWhere((t) => t.id == id);
        return '• ${t.title} — ${fmt.format(t.cost)} $currency';
      }).join('\n')}
━━━━━━━━━━━━━━━━

💰 المجموع: ${fmt.format(subtotal)} $currency
${discount > 0 ? '🏷️ الخصم: ${fmt.format(discount)} $currency\n' : ''}✅ الإجمالي: ${fmt.format(total)} $currency

${_notesController.text.isNotEmpty ? '📝 ${_notesController.text}' : ''}
''';
      Share.share(text);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم إنشاء الفاتورة')),
    );
    context.pop();
  }
}
