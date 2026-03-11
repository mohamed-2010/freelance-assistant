import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class AccountStatementScreen extends ConsumerWidget {
  final String clientId;

  const AccountStatementScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final invoices = ref.watch(allInvoicesProvider);
    final payments = ref.watch(allPaymentsProvider);
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat('#,##0', 'en');

    final client = clients.firstWhere((c) => c.id == clientId);

    // Build statement entries
    final entries = <_StatementEntry>[];

    // Add invoices (debit)
    for (final inv in invoices
        .where((i) => i.clientId == clientId && i.status != 'cancelled')) {
      entries.add(_StatementEntry(
        date: inv.issuedAt,
        description: 'فاتورة #${inv.invoiceNumber} (${inv.taskIds.length} عمل)',
        debit: inv.total,
        credit: 0,
        type: 'invoice',
      ));
    }

    // Add payments (credit)
    for (final pay in payments.where((p) => p.clientId == clientId)) {
      entries.add(_StatementEntry(
        date: pay.date,
        description: 'دفعة${pay.notes.isNotEmpty ? ' — ${pay.notes}' : ''}',
        debit: 0,
        credit: pay.amount,
        type: 'payment',
      ));
    }

    // Sort by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Calculate running balance
    double runningBalance = 0;
    for (final e in entries) {
      runningBalance += e.debit - e.credit;
      e.balance = runningBalance;
    }

    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);

    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حساب — ${client.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareStatement(
                client.name, entries, totalDebit, totalCredit, currency, fmt),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _summaryBox(
                    'إجمالي الفواتير',
                    fmt.format(totalDebit),
                    currency,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryBox(
                    'إجمالي المدفوعات',
                    fmt.format(totalCredit),
                    currency,
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryBox(
                    'الرصيد',
                    fmt.format(runningBalance),
                    currency,
                    runningBalance > 0 ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),

          // Statement table
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text('لا توجد حركات',
                        style: TextStyle(color: Colors.grey.shade500)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final isDebit = e.debit > 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Icon
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isDebit
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                child: Icon(
                                  isDebit
                                      ? Icons.receipt_outlined
                                      : Icons.payments_outlined,
                                  size: 16,
                                  color: isDebit ? Colors.amber : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Description + date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13)),
                                    Text(
                                      DateFormat('yyyy/MM/dd').format(e.date),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isDebit
                                        ? '+${fmt.format(e.debit)}'
                                        : '-${fmt.format(e.credit)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDebit
                                          ? Colors.amber
                                          : Colors.greenAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${fmt.format(e.balance)} $currency',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: e.balance > 0
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, String currency, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '$value $currency',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _shareStatement(
      String clientName,
      List<_StatementEntry> entries,
      double totalDebit,
      double totalCredit,
      String currency,
      NumberFormat fmt) {
    final balance = totalDebit - totalCredit;
    final buffer = StringBuffer();
    buffer.writeln('📊 كشف حساب — $clientName');
    buffer.writeln('📅 ${DateFormat('yyyy/MM/dd').format(DateTime.now())}');
    buffer.writeln('━━━━━━━━━━━━━━━━');

    for (final e in entries) {
      if (e.debit > 0) {
        buffer.writeln(
            '📄 ${DateFormat('MM/dd').format(e.date)} | ${e.description} | +${fmt.format(e.debit)} $currency');
      } else {
        buffer.writeln(
            '💰 ${DateFormat('MM/dd').format(e.date)} | ${e.description} | -${fmt.format(e.credit)} $currency');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('إجمالي الفواتير: ${fmt.format(totalDebit)} $currency');
    buffer.writeln('إجمالي المدفوعات: ${fmt.format(totalCredit)} $currency');
    buffer.writeln('الرصيد المستحق: ${fmt.format(balance)} $currency');

    Share.share(buffer.toString());
  }
}

class _StatementEntry {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final String type;
  double balance;

  _StatementEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.type,
  }) : balance = 0;
}
