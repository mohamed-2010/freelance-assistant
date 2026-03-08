import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardProvider);
    final currency = ref.watch(currencyProvider);
    final fmt =
        NumberFormat.currency(symbol: currency == 'EGP' ? 'EGP ' : '\$');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            toolbarHeight: 72,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _buildSummaryCards(context, summary, fmt),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Recent Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/reports'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
          if (summary.recentTasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'No tasks yet',
                subtitle:
                    'Start by adding a client and project,\nthen log your first task.',
                action: ElevatedButton.icon(
                  onPressed: () => context.go('/clients'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Client'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: summary.recentTasks.length,
                itemBuilder: (context, index) {
                  final task = summary.recentTasks[index];
                  final project = ref.read(allProjectsProvider).where(
                        (p) => p.id == task.projectId,
                      );
                  final projectName =
                      project.isNotEmpty ? project.first.name : 'Unknown';
                  final projectCurrency =
                      project.isNotEmpty ? project.first.currency : currency;
                  final taskFmt = NumberFormat.currency(
                    symbol: projectCurrency == 'EGP' ? 'EGP ' : '\$',
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
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
                            Icon(
                              Icons.folder_outlined,
                              size: 14,
                              color: Colors.white.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                projectName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            taskFmt.format(task.cost),
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
                      onTap: () {
                        context.push(
                            '/tasks-form?id=${task.id}&projectId=${task.projectId}');
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: summary.recentTasks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Quick add — navigate to clients to pick a project
                context.go('/clients');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Task'),
            )
          : null,
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    DashboardSummary summary,
    NumberFormat fmt,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        SummaryCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Unpaid Balance',
          value: fmt.format(summary.totalUnpaid),
          accentColor: AppTheme.warning,
        ),
        SummaryCard(
          icon: Icons.trending_up_rounded,
          title: 'This Month',
          value: fmt.format(summary.thisMonthEarnings),
          accentColor: AppTheme.success,
        ),
        SummaryCard(
          icon: Icons.rocket_launch_rounded,
          title: 'Active Projects',
          value: '${summary.activeProjectsCount}',
          accentColor: AppTheme.invoiced,
        ),
        SummaryCard(
          icon: Icons.people_rounded,
          title: 'Total Clients',
          value: '${summary.totalClients}',
          accentColor: const Color(0xFF9F7AEA),
        ),
      ],
    );
  }
}
