import '../models/task.dart';
import 'database_service.dart';

class TaskRepository {
  final box = DatabaseService.tasksBox;

  List<Task> getAll() {
    return box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Task> getByProjectId(String projectId) {
    return box.values.where((t) => t.projectId == projectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Task> getByStatus(String status) {
    return box.values.where((t) => t.status == status).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Task? getById(String id) {
    try {
      return box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Task task) async {
    await box.put(task.id, task);
  }

  Future<void> update(Task task) async {
    await box.put(task.id, task);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  Future<void> deleteByProjectId(String projectId) async {
    final tasks = getByProjectId(projectId);
    for (final task in tasks) {
      await box.delete(task.id);
    }
  }

  Future<void> clearAll() async {
    await box.clear();
  }

  Future<void> addAll(List<Task> tasks) async {
    for (final task in tasks) {
      await box.put(task.id, task);
    }
  }

  // Financial aggregation helpers
  double getTotalCostForProject(String projectId) {
    return getByProjectId(projectId).fold(0.0, (sum, t) => sum + t.cost);
  }

  double getPaidForProject(String projectId) {
    return getByProjectId(projectId)
        .where((t) => t.status == 'paid')
        .fold(0.0, (sum, t) => sum + t.cost);
  }

  double getInvoicedForProject(String projectId) {
    return getByProjectId(projectId)
        .where((t) => t.status == 'invoiced')
        .fold(0.0, (sum, t) => sum + t.cost);
  }

  double getPendingForProject(String projectId) {
    return getByProjectId(projectId)
        .where((t) => t.status == 'pending')
        .fold(0.0, (sum, t) => sum + t.cost);
  }

  double getUnpaidTotal() {
    return box.values
        .where((t) => t.status != 'paid')
        .fold(0.0, (sum, t) => sum + t.cost);
  }

  double getThisMonthEarnings() {
    final now = DateTime.now();
    return box.values
        .where((t) =>
            t.status == 'paid' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.cost);
  }
}
