import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  static const _methodIcons = {
    'cash': '💵',
    'instapay': '📱',
    'bank_transfer': '🏦',
    'vodafone_cash': '📲',
    'other': '💳',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(allPaymentsProvider);
    final clients = ref.watch(clientsProvider);
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat('#,##0', 'en');

    final sorted = List<Payment>.from(payments)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('المدفوعات',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'إجمالي: ${fmt.format(totalPaid)} $currency',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (sorted.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.payments_outlined,
                title: 'لا توجد مدفوعات',
                subtitle: 'اضغط + لتسجيل دفعة جديدة',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = sorted[index];
                  final client = clients.firstWhere(
                    (c) => c.id == p.clientId,
                    orElse: () => clients.first,
                  );
                  final icon = _methodIcons[p.method] ?? '💳';

                  return Dismissible(
                    key: Key(p.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red.shade900,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await ConfirmDialog.show(
                        context,
                        title: 'حذف الدفعة',
                        message:
                            'هل تريد حذف دفعة ${fmt.format(p.amount)} $currency؟',
                      );
                    },
                    onDismissed: (_) {
                      ref.read(allPaymentsProvider.notifier).delete(p.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف الدفعة')),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        onTap: () => context.push('/payments/edit?id=${p.id}&clientId=${p.clientId}'),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          child:
                              Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          '${fmt.format(p.amount)} $currency',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        subtitle: Text(
                          '${client.name} • ${DateFormat('yyyy/MM/dd').format(p.date)}',
                        ),
                        trailing: p.notes.isNotEmpty
                            ? Tooltip(
                                message: p.notes,
                                child: const Icon(Icons.info_outline, size: 18),
                              )
                            : null,
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/payments/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
