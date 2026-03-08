import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/client_repository.dart';
import '../data/project_repository.dart';
import '../data/task_repository.dart';
import '../data/backup_service.dart';
import '../data/database_service.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';

const _uuid = Uuid();

// ── Repositories ──────────────────────────────────────────────
final clientRepositoryProvider = Provider((_) => ClientRepository());
final projectRepositoryProvider = Provider((_) => ProjectRepository());
final taskRepositoryProvider = Provider((_) => TaskRepository());

final backupServiceProvider = Provider((ref) => BackupService(
      clientRepo: ref.read(clientRepositoryProvider),
      projectRepo: ref.read(projectRepositoryProvider),
      taskRepo: ref.read(taskRepositoryProvider),
    ));

// ── Settings ──────────────────────────────────────────────────
final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier()
      : super(DatabaseService.settingsBox.get('currency', defaultValue: 'EGP')
            as String);

  void setCurrency(String currency) {
    state = currency;
    DatabaseService.settingsBox.put('currency', currency);
  }
}

// ── Clients ───────────────────────────────────────────────────
final clientsProvider =
    StateNotifierProvider<ClientsNotifier, List<Client>>((ref) {
  return ClientsNotifier(ref.read(clientRepositoryProvider));
});

class ClientsNotifier extends StateNotifier<List<Client>> {
  final ClientRepository _repo;

  ClientsNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> add({
    required String name,
    String contact = '',
    String notes = '',
  }) async {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      contact: contact,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _repo.add(client);
    _load();
  }

  Future<void> update(Client client) async {
    await _repo.update(client);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  void refresh() => _load();
}

// ── Projects ──────────────────────────────────────────────────
final allProjectsProvider =
    StateNotifierProvider<AllProjectsNotifier, List<Project>>((ref) {
  return AllProjectsNotifier(ref.read(projectRepositoryProvider));
});

class AllProjectsNotifier extends StateNotifier<List<Project>> {
  final ProjectRepository _repo;

  AllProjectsNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  List<Project> getByClient(String clientId) {
    return state.where((p) => p.clientId == clientId).toList();
  }

  Future<void> add({
    required String clientId,
    required String name,
    String description = '',
    String status = 'active',
    String currency = 'EGP',
  }) async {
    final project = Project(
      id: _uuid.v4(),
      clientId: clientId,
      name: name,
      description: description,
      status: status,
      currency: currency,
      createdAt: DateTime.now(),
    );
    await _repo.add(project);
    _load();
  }

  Future<void> update(Project project) async {
    await _repo.update(project);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> deleteByClient(String clientId) async {
    await _repo.deleteByClientId(clientId);
    _load();
  }

  void refresh() => _load();
}

// ── Tasks ─────────────────────────────────────────────────────
final allTasksProvider =
    StateNotifierProvider<AllTasksNotifier, List<Task>>((ref) {
  return AllTasksNotifier(ref.read(taskRepositoryProvider));
});

class AllTasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repo;

  AllTasksNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  List<Task> getByProject(String projectId) {
    return state.where((t) => t.projectId == projectId).toList();
  }

  Future<void> add({
    required String projectId,
    required String title,
    String description = '',
    double cost = 0.0,
    required DateTime date,
    String status = 'pending',
  }) async {
    final task = Task(
      id: _uuid.v4(),
      projectId: projectId,
      title: title,
      description: description,
      cost: cost,
      date: date,
      status: status,
      createdAt: DateTime.now(),
    );
    await _repo.add(task);
    _load();
  }

  Future<void> update(Task task) async {
    await _repo.update(task);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> deleteByProject(String projectId) async {
    await _repo.deleteByProjectId(projectId);
    _load();
  }

  Future<void> toggleStatus(Task task) async {
    String nextStatus;
    switch (task.status) {
      case 'pending':
        nextStatus = 'invoiced';
        break;
      case 'invoiced':
        nextStatus = 'paid';
        break;
      case 'paid':
        nextStatus = 'pending';
        break;
      default:
        nextStatus = 'pending';
    }
    final updated = Task(
      id: task.id,
      projectId: task.projectId,
      title: task.title,
      description: task.description,
      cost: task.cost,
      date: task.date,
      status: nextStatus,
      createdAt: task.createdAt,
    );
    await _repo.update(updated);
    _load();
  }

  void refresh() => _load();
}

// ── Dashboard Summary ─────────────────────────────────────────
class DashboardSummary {
  final double totalUnpaid;
  final double thisMonthEarnings;
  final int activeProjectsCount;
  final int totalClients;
  final List<Task> recentTasks;

  DashboardSummary({
    required this.totalUnpaid,
    required this.thisMonthEarnings,
    required this.activeProjectsCount,
    required this.totalClients,
    required this.recentTasks,
  });
}

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final tasks = ref.watch(allTasksProvider);
  final projects = ref.watch(allProjectsProvider);
  final clients = ref.watch(clientsProvider);

  final now = DateTime.now();
  final totalUnpaid = tasks
      .where((t) => t.status != 'paid')
      .fold(0.0, (sum, t) => sum + t.cost);
  final thisMonthEarnings = tasks
      .where((t) =>
          t.status == 'paid' &&
          t.date.year == now.year &&
          t.date.month == now.month)
      .fold(0.0, (sum, t) => sum + t.cost);
  final activeCount = projects.where((p) => p.status == 'active').length;
  final recentTasks = List<Task>.from(tasks)
    ..sort((a, b) => b.date.compareTo(a.date));

  return DashboardSummary(
    totalUnpaid: totalUnpaid,
    thisMonthEarnings: thisMonthEarnings,
    activeProjectsCount: activeCount,
    totalClients: clients.length,
    recentTasks: recentTasks.take(10).toList(),
  );
});
