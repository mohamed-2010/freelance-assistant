import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../models/invoice.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class InvoicesListScreen extends ConsumerWidget {
  const InvoicesListScreen({super.key});

  static const _statusColors = {
    'draft': Colors.grey,
    'sent': Colors.blue,
    'paid': Colors.green,
    'cancelled': Colors.red,
  };

  static const _statusLabels = {
    'draft': 'مسودة',
    'sent': 'مُرسلة',
    'paid': 'مدفوعة',
    'cancelled': 'ملغاة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(allInvoicesProvider);
    final clients = ref.watch(clientsProvider);
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat('#,##0', 'en');

    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('الفواتير',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              ),
            ),
          ),
          if (sorted.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'لا توجد فواتير',
                subtitle: 'اضغط + لإنشاء فاتورة جديدة',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final inv = sorted[index];
                  final client = clients.firstWhere(
                    (c) => c.id == inv.clientId,
                    orElse: () => clients.first,
                  );
                  final statusColor = _statusColors[inv.status] ?? Colors.grey;
                  final statusLabel = _statusLabels[inv.status] ?? inv.status;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        child: Text('#${inv.invoiceNumber}',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      title: Text(
                        '${fmt.format(inv.total)} $currency',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${client.name} • ${DateFormat('yyyy/MM/dd').format(inv.issuedAt)} • ${inv.taskIds.length} عمل',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      onTap: () {
                        context.push('/invoices/${inv.id}');
                      },
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/invoices/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

}
