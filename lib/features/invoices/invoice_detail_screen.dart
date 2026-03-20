import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/pdf_service.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

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
    final invoice = invoices.where((i) => i.id == invoiceId).firstOrNull;
    final clients = ref.watch(clientsProvider);
    final allTasks = ref.watch(allTasksProvider);
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat('#,##0', 'en');

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('الفاتورة غير موجودة')),
      );
    }

    final client = clients.where((c) => c.id == invoice.clientId).firstOrNull;
    final tasks =
        allTasks.where((t) => invoice.taskIds.contains(t.id)).toList();
    final statusColor = _statusColors[invoice.status] ?? Colors.grey;
    final statusLabel = _statusLabels[invoice.status] ?? invoice.status;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'فاتورة #${invoice.invoiceNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(statusLabel,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${client?.name ?? "—"} • ${DateFormat('yyyy/MM/dd').format(invoice.issuedAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // PDF Export
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'تصدير PDF',
                onPressed: client == null
                    ? null
                    : () => _exportPdf(context, ref, invoice, client, tasks,
                        currency),
              ),
              // WhatsApp Share
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'مشاركة',
                onPressed: () => _shareText(
                    invoice, client, tasks, fmt, currency),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'حذف الفاتورة',
                    message: 'هل تريد حذف فاتورة #${invoice.invoiceNumber}؟',
                  );
                  if (confirmed == true && context.mounted) {
                    ref.read(allInvoicesProvider.notifier).delete(invoice.id);
                    context.pop();
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Totals card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14)),
                      Text('${fmt.format(invoice.subtotal)} $currency',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  if (invoice.discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الخصم',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14)),
                        Text('- ${fmt.format(invoice.discount)} $currency',
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 16)),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإجمالي',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.amberAccent)),
                      Text('${fmt.format(invoice.total)} $currency',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.amberAccent)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  if (invoice.status == 'draft')
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.send_rounded,
                        label: 'إرسال',
                        color: Colors.blue,
                        onTap: () {
                          ref
                              .read(allInvoicesProvider.notifier)
                              .markAsSent(invoice);
                        },
                      ),
                    ),
                  if (invoice.status == 'draft') const SizedBox(width: 8),
                  if (invoice.status != 'paid' &&
                      invoice.status != 'cancelled')
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.check_circle_rounded,
                        label: 'مدفوعة',
                        color: Colors.green,
                        onTap: () {
                          ref
                              .read(allInvoicesProvider.notifier)
                              .markAsPaid(invoice);
                        },
                      ),
                    ),
                  if (invoice.status != 'paid' &&
                      invoice.status != 'cancelled')
                    const SizedBox(width: 8),
                  if (invoice.status != 'cancelled')
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.cancel_rounded,
                        label: 'إلغاء',
                        color: Colors.red,
                        onTap: () {
                          final updated = invoice.copyWith(status: 'cancelled');
                          ref.read(allInvoicesProvider.notifier).update(updated);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Notes
          if (invoice.notes.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 16, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        invoice.notes,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tasks header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'الأعمال',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tasks list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final projects = ref.read(allProjectsProvider);
                final project =
                    projects.where((p) => p.id == task.projectId).firstOrNull;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    title: Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: project != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          )
                        : null,
                    trailing: Text(
                      '${fmt.format(task.cost)} $currency',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
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

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _exportPdf(BuildContext context, WidgetRef ref, invoice, client, tasks,
      String currency) async {
    try {
      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        client: client,
        tasks: tasks,
        currency: currency,
      );

      if (!context.mounted) return;

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'فاتورة_${invoice.invoiceNumber}_${client.name}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل التصدير: $e')),
        );
      }
    }
  }

  void _shareText(invoice, client, tasks, NumberFormat fmt, String currency) {
    final text = '''
📄 فاتورة رقم #${invoice.invoiceNumber}
👤 العميل: ${client?.name ?? '—'}
📅 التاريخ: ${DateFormat('yyyy/MM/dd').format(invoice.issuedAt)}

━━━━━━━━━━━━━━━━
${tasks.map((t) => '• ${t.title} — ${fmt.format(t.cost)} $currency').join('\n')}
━━━━━━━━━━━━━━━━

💰 المجموع: ${fmt.format(invoice.subtotal)} $currency
${invoice.discount > 0 ? '🏷️ الخصم: ${fmt.format(invoice.discount)} $currency\n' : ''}✅ الإجمالي: ${fmt.format(invoice.total)} $currency
${invoice.notes.isNotEmpty ? '\n📝 ${invoice.notes}' : ''}
''';
    Share.share(text);
  }
}
