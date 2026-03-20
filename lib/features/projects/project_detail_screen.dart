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

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(allProjectsProvider);
    final project = projects.where((p) => p.id == projectId).firstOrNull;
    final tasks = ref
        .watch(allTasksProvider)
        .where((t) => t.projectId == projectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Project not found')),
      );
    }

    final fmt = NumberFormat.currency(
      symbol: project.currency == 'EGP' ? 'EGP ' : '\$',
    );
    final totalCost = tasks.fold(0.0, (sum, t) => sum + t.cost);
    final totalDelivered = tasks
        .where((t) => t.status == 'delivered')
        .fold(0.0, (sum, t) => sum + t.cost);
    final totalDone = tasks
        .where((t) => t.status == 'done' || t.status == 'review')
        .fold(0.0, (sum, t) => sum + t.cost);
    final totalPending = tasks
        .where((t) => t.status == 'pending' || t.status == 'in_progress')
        .fold(0.0, (sum, t) => sum + t.cost);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.accentGradient,
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
                            Expanded(
                              child: Text(
                                project.name,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            StatusChip(status: project.status),
                          ],
                        ),
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            project.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                onPressed: () => context.push(
                  '/projects-form?id=${project.id}&clientId=${project.clientId}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Delete Project',
                    message:
                        'This will delete "${project.name}" and all its tasks. This action cannot be undone.',
                  );
                  if (confirmed == true && context.mounted) {
                    ref
                        .read(allTasksProvider.notifier)
                        .deleteByProject(projectId);
                    ref.read(allProjectsProvider.notifier).delete(projectId);
                    context.pop();
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Financial summary
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _financialItem(
                          'Total', fmt.format(totalCost), Colors.white),
                      _divider(),
                      _financialItem(
                          'Delivered', fmt.format(totalDelivered), AppTheme.paid),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _financialItem('Done/Review', fmt.format(totalDone),
                          AppTheme.invoiced),
                      _divider(),
                      _financialItem('Pending', fmt.format(totalPending),
                          AppTheme.pending),
                    ],
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
                    'Tasks',
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
          if (tasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.task_rounded,
                title: 'No tasks yet',
                subtitle: 'Log your first task for this project.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: AppTheme.error),
                    ),
                    confirmDismiss: (direction) async {
                      return await ConfirmDialog.show(
                        context,
                        title: 'Delete Task',
                        message: 'Delete "${task.title}"?',
                      );
                    },
                    onDismissed: (_) {
                      ref.read(allTasksProvider.notifier).delete(task.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          task.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.3)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(task.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(task.cost),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            StatusChip(
                              status: task.status,
                              showIcon: false,
                              onTap: () {
                                ref
                                    .read(allTasksProvider.notifier)
                                    .toggleStatus(task);
                              },
                            ),
                          ],
                        ),
                        onTap: () => context.push(
                          '/tasks-form?id=${task.id}&projectId=${task.projectId}',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_task_$projectId',
        onPressed: () => context.push('/tasks-form?projectId=$projectId'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
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
