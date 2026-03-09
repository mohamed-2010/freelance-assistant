import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/client_repository.dart';
import '../data/project_repository.dart';
import '../data/task_repository.dart';
import '../data/payment_repository.dart';
import '../data/invoice_repository.dart';
import '../data/backup_service.dart';
import '../data/database_service.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../models/invoice.dart';

const _uuid = Uuid();

// ── Repositories ──────────────────────────────────────────────
final clientRepositoryProvider = Provider((_) => ClientRepository());
final projectRepositoryProvider = Provider((_) => ProjectRepository());
final taskRepositoryProvider = Provider((_) => TaskRepository());
final paymentRepositoryProvider = Provider((_) => PaymentRepository());
final invoiceRepositoryProvider = Provider((_) => InvoiceRepository());

final backupServiceProvider = Provider((ref) => BackupService(
      clientRepo: ref.read(clientRepositoryProvider),
      projectRepo: ref.read(projectRepositoryProvider),
      taskRepo: ref.read(taskRepositoryProvider),
      paymentRepo: ref.read(paymentRepositoryProvider),
      invoiceRepo: ref.read(invoiceRepositoryProvider),
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
    String priority = 'medium',
  }) async {
    final task = Task(
      id: _uuid.v4(),
      projectId: projectId,
      title: title,
      description: description,
      cost: cost,
      date: date,
      status: status,
      priority: priority,
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
    DateTime? completedAt = task.completedAt;
    DateTime? deliveredAt = task.deliveredAt;

    switch (task.status) {
      case 'pending':
        nextStatus = 'in_progress';
        break;
      case 'in_progress':
        nextStatus = 'review';
        break;
      case 'review':
        nextStatus = 'done';
        completedAt = DateTime.now();
        break;
      case 'done':
        nextStatus = 'delivered';
        deliveredAt = DateTime.now();
        break;
      case 'delivered':
        nextStatus = 'pending';
        completedAt = null;
        deliveredAt = null;
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
      priority: task.priority,
      completedAt: completedAt,
      deliveredAt: deliveredAt,
    );
    await _repo.update(updated);
    _load();
  }

  void refresh() => _load();
}

// ── Payments ──────────────────────────────────────────────────
final allPaymentsProvider =
    StateNotifierProvider<AllPaymentsNotifier, List<Payment>>((ref) {
  return AllPaymentsNotifier(ref.read(paymentRepositoryProvider));
});

class AllPaymentsNotifier extends StateNotifier<List<Payment>> {
  final PaymentRepository _repo;

  AllPaymentsNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  List<Payment> getByClient(String clientId) {
    return state.where((p) => p.clientId == clientId).toList();
  }

  Future<void> add({
    required String clientId,
    String? projectId,
    required double amount,
    required DateTime date,
    String method = 'cash',
    String notes = '',
  }) async {
    final payment = Payment(
      id: _uuid.v4(),
      clientId: clientId,
      projectId: projectId,
      amount: amount,
      date: date,
      method: method,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _repo.add(payment);
    _load();
  }

  Future<void> update(Payment payment) async {
    await _repo.update(payment);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  void refresh() => _load();
}

// ── Invoices ──────────────────────────────────────────────────
final allInvoicesProvider =
    StateNotifierProvider<AllInvoicesNotifier, List<Invoice>>((ref) {
  return AllInvoicesNotifier(ref.read(invoiceRepositoryProvider));
});

class AllInvoicesNotifier extends StateNotifier<List<Invoice>> {
  final InvoiceRepository _repo;

  AllInvoicesNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  List<Invoice> getByClient(String clientId) {
    return state.where((i) => i.clientId == clientId).toList();
  }

  Future<void> add({
    required String clientId,
    required List<String> taskIds,
    required double subtotal,
    double discount = 0.0,
    String notes = '',
  }) async {
    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: _repo.getNextInvoiceNumber(),
      clientId: clientId,
      taskIds: taskIds,
      subtotal: subtotal,
      discount: discount,
      total: subtotal - discount,
      status: 'draft',
      issuedAt: DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _repo.add(invoice);
    _load();
  }

  Future<void> update(Invoice invoice) async {
    await _repo.update(invoice);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> markAsSent(Invoice invoice) async {
    final updated = invoice.copyWith(status: 'sent');
    await _repo.update(updated);
    _load();
  }

  Future<void> markAsPaid(Invoice invoice) async {
    final updated = invoice.copyWith(status: 'paid', paidAt: DateTime.now());
    await _repo.update(updated);
    _load();
  }

  void refresh() => _load();
}

// ── Dashboard Summary ─────────────────────────────────────────
class DashboardSummary {
  final double totalBilled;
  final double totalPaid;
  final double totalOutstanding;
  final double thisMonthCollections;
  final int activeProjectsCount;
  final int totalClients;
  final int pendingTasks;
  final int inProgressTasks;
  final int doneTasks;
  final List<Task> recentTasks;

  DashboardSummary({
    required this.totalBilled,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.thisMonthCollections,
    required this.activeProjectsCount,
    required this.totalClients,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.doneTasks,
    required this.recentTasks,
  });
}

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final tasks = ref.watch(allTasksProvider);
  final projects = ref.watch(allProjectsProvider);
  final clients = ref.watch(clientsProvider);
  final payments = ref.watch(allPaymentsProvider);
  final invoices = ref.watch(allInvoicesProvider);

  final now = DateTime.now();

  // Total billed = sum of all invoice totals (not cancelled)
  final totalBilled = invoices
      .where((i) => i.status != 'cancelled')
      .fold(0.0, (sum, i) => sum + i.total);

  // Total paid = sum of all payments
  final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

  // Outstanding = billed - paid
  final totalOutstanding = totalBilled - totalPaid;

  // This month's collections
  final thisMonthCollections = payments
      .where((p) => p.date.year == now.year && p.date.month == now.month)
      .fold(0.0, (sum, p) => sum + p.amount);

  final activeCount = projects.where((p) => p.status == 'active').length;
  final pendingTasks = tasks.where((t) => t.status == 'pending').length;
  final inProgressTasks = tasks
      .where((t) => t.status == 'in_progress' || t.status == 'review')
      .length;
  final doneTasks =
      tasks.where((t) => t.status == 'done' || t.status == 'delivered').length;

  final recentTasks = List<Task>.from(tasks)
    ..sort((a, b) => b.date.compareTo(a.date));

  return DashboardSummary(
    totalBilled: totalBilled,
    totalPaid: totalPaid,
    totalOutstanding: totalOutstanding,
    thisMonthCollections: thisMonthCollections,
    activeProjectsCount: activeCount,
    totalClients: clients.length,
    pendingTasks: pendingTasks,
    inProgressTasks: inProgressTasks,
    doneTasks: doneTasks,
    recentTasks: recentTasks.take(10).toList(),
  );
});
