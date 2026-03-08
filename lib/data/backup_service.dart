import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'database_service.dart';
import 'client_repository.dart';
import 'project_repository.dart';
import 'task_repository.dart';

class BackupService {
  final ClientRepository _clientRepo;
  final ProjectRepository _projectRepo;
  final TaskRepository _taskRepo;

  BackupService({
    required ClientRepository clientRepo,
    required ProjectRepository projectRepo,
    required TaskRepository taskRepo,
  })  : _clientRepo = clientRepo,
        _projectRepo = projectRepo,
        _taskRepo = taskRepo;

  /// Export all data to a JSON file and share it
  Future<void> exportBackup() async {
    final data = {
      'backup_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'clients': _clientRepo.getAll().map((c) => c.toJson()).toList(),
      'projects': _projectRepo.getAll().map((p) => p.toJson()).toList(),
      'tasks': _taskRepo.getAll().map((t) => t.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/freelance_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    // Save last backup date
    await DatabaseService.settingsBox
        .put('lastBackupDate', DateTime.now().toIso8601String());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Freelance Assistant Backup',
      text: 'Freelance Assistant data backup — $timestamp',
    );
  }

  /// Import data from a picked JSON file
  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (!data.containsKey('backup_version') ||
          !data.containsKey('clients') ||
          !data.containsKey('projects') ||
          !data.containsKey('tasks')) {
        return false;
      }

      // Parse data
      final clients = (data['clients'] as List)
          .map((c) => Client.fromJson(c as Map<String, dynamic>))
          .toList();
      final projects = (data['projects'] as List)
          .map((p) => Project.fromJson(p as Map<String, dynamic>))
          .toList();
      final tasks = (data['tasks'] as List)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList();

      // Clear existing data
      await _clientRepo.clearAll();
      await _projectRepo.clearAll();
      await _taskRepo.clearAll();

      // Restore data
      await _clientRepo.addAll(clients);
      await _projectRepo.addAll(projects);
      await _taskRepo.addAll(tasks);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the last backup date
  DateTime? getLastBackupDate() {
    final dateStr =
        DatabaseService.settingsBox.get('lastBackupDate') as String?;
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Check if backup reminder should be shown (>7 days since last backup)
  bool shouldRemindBackup() {
    final lastBackup = getLastBackupDate();
    if (lastBackup == null) return true;
    return DateTime.now().difference(lastBackup).inDays >= 7;
  }
}
