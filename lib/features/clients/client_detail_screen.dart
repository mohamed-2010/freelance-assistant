import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final client = clients.where((c) => c.id == clientId).firstOrNull;
    final projects = ref
        .watch(allProjectsProvider)
        .where((p) => p.clientId == clientId)
        .toList();
    final tasks = ref.watch(allTasksProvider);
    final currency = ref.watch(currencyProvider);
    final fmt =
        NumberFormat.currency(symbol: currency == 'EGP' ? 'EGP ' : '\$');

    if (client == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Client not found')),
      );
    }

    // Calculate client-level financials
    final clientTasks = tasks.where((t) {
      return projects.any((p) => p.id == t.projectId);
    }).toList();
    final totalCost = clientTasks.fold(0.0, (sum, t) => sum + t.cost);
    final totalPaid = clientTasks
        .where((t) => t.status == 'paid')
        .fold(0.0, (sum, t) => sum + t.cost);
    final totalUnpaid = totalCost - totalPaid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
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
                        Text(
                          client.name,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (client.contact.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.contact_mail_outlined,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                client.contact,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/clients-form?id=${client.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Delete Client',
                    message:
                        'This will delete "${client.name}" and all their projects and tasks. This action cannot be undone.',
                  );
                  if (confirmed == true && context.mounted) {
                    // Delete all tasks of client's projects
                    for (final project in projects) {
                      ref
                          .read(allTasksProvider.notifier)
                          .deleteByProject(project.id);
                    }
                    ref
                        .read(allProjectsProvider.notifier)
                        .deleteByClient(clientId);
                    ref.read(clientsProvider.notifier).delete(clientId);
                    context.pop();
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Financial summary bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  _financialItem('Total', fmt.format(totalCost), Colors.white),
                  _divider(),
                  _financialItem('Paid', fmt.format(totalPaid), AppTheme.paid),
                  _divider(),
                  _financialItem(
                    'Unpaid',
                    fmt.format(totalUnpaid),
                    totalUnpaid > 0 ? AppTheme.warning : AppTheme.paid,
                  ),
                ],
              ),
            ),
          ),

          // Notes
          if (client.notes.isNotEmpty)
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
                        client.notes,
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

          // Projects header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Projects',
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
                      '${projects.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Projects list
          if (projects.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No projects yet',
                subtitle: 'Create a project for this client.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final projectTasks =
                      tasks.where((t) => t.projectId == project.id).toList();
                  final projectTotal =
                      projectTasks.fold(0.0, (sum, t) => sum + t.cost);
                  final projectFmt = NumberFormat.currency(
                    symbol: project.currency == 'EGP' ? 'EGP ' : '\$',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          StatusChip(status: project.status, showIcon: true),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_outlined,
                                size: 14, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              '${projectTasks.length} tasks',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              projectFmt.format(projectTotal),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white24),
                      onTap: () => context.push('/projects/${project.id}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_project_${clientId}',
        onPressed: () => context.push('/projects-form?clientId=$clientId'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _financialItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.08),
    );
  }
}
