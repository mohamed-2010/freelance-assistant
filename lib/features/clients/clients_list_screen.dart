import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final projects = ref.watch(allProjectsProvider);
    final tasks = ref.watch(allTasksProvider);
    final currency = ref.watch(currencyProvider);
    final fmt =
        NumberFormat.currency(symbol: currency == 'EGP' ? 'EGP ' : '\$');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              'Clients',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded),
                onPressed: () => context.push('/clients-form'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (clients.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No clients yet',
                subtitle:
                    'Add your first client to start\ntracking projects and tasks.',
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/clients-form'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Client'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  final clientProjects =
                      projects.where((p) => p.clientId == client.id).toList();
                  final clientTasks = tasks.where((t) {
                    return clientProjects.any((p) => p.id == t.projectId);
                  }).toList();
                  final unpaid = clientTasks
                      .where((t) => t.status != 'paid')
                      .fold(0.0, (sum, t) => sum + t.cost);
                  final activeCount =
                      clientProjects.where((p) => p.status == 'active').length;

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
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        client.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            _miniStat(
                              Icons.folder_outlined,
                              '$activeCount project${activeCount != 1 ? 's' : ''}',
                            ),
                            const SizedBox(width: 12),
                            if (unpaid > 0)
                              _miniStat(
                                Icons.account_balance_wallet_outlined,
                                fmt.format(unpaid),
                                color: AppTheme.warning,
                              ),
                          ],
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white24,
                      ),
                      onTap: () => context.push('/clients/${client.id}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_client',
        onPressed: () => context.push('/clients-form'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.white.withOpacity(0.4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
