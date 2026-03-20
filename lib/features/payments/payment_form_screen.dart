import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? clientId;
  final String? paymentId;

  const PaymentFormScreen({super.key, this.clientId, this.paymentId});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedClientId;
  String? _selectedProjectId;
  DateTime _selectedDate = DateTime.now();
  String _selectedMethod = 'cash';

  static const _methods = {
    'cash': '💵 كاش',
    'instapay': '📱 إنستاباي',
    'bank_transfer': '🏦 تحويل بنكي',
    'vodafone_cash': '📲 فودافون كاش',
    'other': '💳 أخرى',
  };

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;

    if (widget.paymentId != null) {
      final payment = ref
          .read(allPaymentsProvider)
          .where((p) => p.id == widget.paymentId)
          .firstOrNull;
      if (payment != null) {
        _isEdit = true;
        _selectedClientId = payment.clientId;
        _selectedProjectId = payment.projectId;
        _amountController.text = payment.amount.toStringAsFixed(0);
        _notesController.text = payment.notes;
        _selectedDate = payment.date;
        _selectedMethod = payment.method;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final projects = ref.watch(allProjectsProvider);
    final currency = ref.watch(currencyProvider);

    final clientProjects = _selectedClientId != null
        ? projects.where((p) => p.clientId == _selectedClientId).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل دفعة' : 'تسجيل دفعة'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedClientId = v;
                _selectedProjectId = null;
              }),
              validator: (v) => v == null ? 'اختار العميل' : null,
            ),
            const SizedBox(height: 16),

            // Project selector (optional)
            if (clientProjects.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'المشروع (اختياري)',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('— بدون مشروع —')),
                  ...clientProjects.map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
            if (clientProjects.isNotEmpty) const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ *',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: currency,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'ادخل المبلغ';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'ادخل مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('التاريخ'),
              subtitle: Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 16),

            // Payment method
            const Text('طريقة الدفع',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methods.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _selectedMethod == e.key,
                        onSelected: (_) =>
                            setState(() => _selectedMethod = e.key),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEdit ? 'حفظ التعديلات' : 'حفظ الدفعة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit && widget.paymentId != null) {
      final existing = ref
          .read(allPaymentsProvider)
          .where((p) => p.id == widget.paymentId)
          .first;
      final updated = existing.copyWith(
        clientId: _selectedClientId!,
        projectId: _selectedProjectId,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        method: _selectedMethod,
        notes: _notesController.text,
      );
      ref.read(allPaymentsProvider.notifier).update(updated);
    } else {
      ref.read(allPaymentsProvider.notifier).add(
            clientId: _selectedClientId!,
            projectId: _selectedProjectId,
            amount: double.parse(_amountController.text),
            date: _selectedDate,
            method: _selectedMethod,
            notes: _notesController.text,
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? '✅ تم تعديل الدفعة بنجاح' : '✅ تم تسجيل الدفعة بنجاح')),
    );
    context.pop();
  }
}
