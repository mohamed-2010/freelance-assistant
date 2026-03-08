import '../models/project.dart';
import 'database_service.dart';

class ProjectRepository {
  final box = DatabaseService.projectsBox;

  List<Project> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Project> getByClientId(String clientId) {
    return box.values.where((p) => p.clientId == clientId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Project? getById(String id) {
    try {
      return box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Project project) async {
    await box.put(project.id, project);
  }

  Future<void> update(Project project) async {
    await box.put(project.id, project);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  Future<void> deleteByClientId(String clientId) async {
    final projects = getByClientId(clientId);
    for (final project in projects) {
      await box.delete(project.id);
    }
  }

  Future<void> clearAll() async {
    await box.clear();
  }

  Future<void> addAll(List<Project> projects) async {
    for (final project in projects) {
      await box.put(project.id, project);
    }
  }
}
