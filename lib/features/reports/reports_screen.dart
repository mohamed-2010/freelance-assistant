import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../models/task.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _statusFilter = 'all';
  String _sortBy = 'date';
  String? _clientFilter;
  String? _projectFilter;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(allTasksProvider);
    final projects = ref.watch(allProjectsProvider);
    final clients = ref.watch(clientsProvider);
    final currency = ref.watch(currencyProvider);
    final fmt =
        NumberFormat.currency(symbol: currency == 'EGP' ? 'EGP ' : '\$');

    // Apply filters
    List<Task> filtered = List.from(allTasks);

    if (_statusFilter != 'all') {
      filtered = filtered.where((t) => t.status == _statusFilter).toList();
    }

    if (_clientFilter != null) {
      final clientProjects = projects
          .where((p) => p.clientId == _clientFilter)
          .map((p) => p.id)
          .toSet();
      filtered =
          filtered.where((t) => clientProjects.contains(t.projectId)).toList();
    }

    if (_projectFilter != null) {
      filtered = filtered.where((t) => t.projectId == _projectFilter).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'cost_high':
        filtered.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'status':
        const order = {
          'pending': 0,
          'in_progress': 1,
          'review': 2,
          'done': 3,
          'delivered': 4,
        };
        filtered.sort(
            (a, b) => (order[a.status] ?? 0).compareTo(order[b.status] ?? 0));
        break;
    }

    final totalFiltered = filtered.fold(0.0, (sum, t) => sum + t.cost);
    final unpaidFiltered = filtered
        .where((t) => t.status != 'delivered')
        .fold(0.0, (sum, t) => sum + t.cost);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              'Reports',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Summary bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          fmt.format(totalFiltered),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          fmt.format(unpaidFiltered),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unpaid',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${filtered.length}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('All', _statusFilter == 'all',
                      () => setState(() => _statusFilter = 'all')),
                  const SizedBox(width: 8),
                  _filterChip('Pending', _statusFilter == 'pending',
                      () => setState(() => _statusFilter = 'pending'),
                      color: AppTheme.pending),
                  const SizedBox(width: 8),
                  _filterChip('In Progress', _statusFilter == 'in_progress',
                      () => setState(() => _statusFilter = 'in_progress'),
                      color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  _filterChip('Review', _statusFilter == 'review',
                      () => setState(() => _statusFilter = 'review'),
                      color: AppTheme.invoiced),
                  const SizedBox(width: 8),
                  _filterChip('Done', _statusFilter == 'done',
                      () => setState(() => _statusFilter = 'done'),
                      color: Colors.cyan),
                  const SizedBox(width: 8),
                  _filterChip('Delivered', _statusFilter == 'delivered',
                      () => setState(() => _statusFilter = 'delivered'),
                      color: AppTheme.paid),
                ],
              ),
            ),
          ),

          // Client & Project dropdown filters + Sort
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _dropdownFilter(
                      hint: 'Client',
                      value: _clientFilter,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Clients')),
                        ...clients.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() {
                        _clientFilter = v;
                        _projectFilter = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sortDropdown(),
                ],
              ),
            ),
          ),

          // Tasks list
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.filter_list_rounded,
                title: 'No matching tasks',
                subtitle: 'Try adjusting your filters.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final task = filtered[index];
                  final project =
                      projects.where((p) => p.id == task.projectId).firstOrNull;
                  final projectName = project?.name ?? 'Unknown';
                  final taskFmt = NumberFormat.currency(
                    symbol: project?.currency == 'USD' ? '\$' : 'EGP ',
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
                            Icon(Icons.folder_outlined,
                                size: 14, color: Colors.white.withOpacity(0.4)),
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
                            Text(
                              DateFormat('MMM d').format(task.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.3),
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
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
      {Color? color}) {
    final chipColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? chipColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? chipColor : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdownFilter({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          isExpanded: true,
          dropdownColor: AppTheme.surfaceContainerHigh,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _sortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          dropdownColor: AppTheme.surfaceContainerHigh,
          items: const [
            DropdownMenuItem(value: 'date', child: Text('Date')),
            DropdownMenuItem(value: 'cost_high', child: Text('Cost ↓')),
            DropdownMenuItem(value: 'status', child: Text('Status')),
          ],
          onChanged: (v) => setState(() => _sortBy = v!),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
          icon: Icon(Icons.sort_rounded,
              size: 18, color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }
}
