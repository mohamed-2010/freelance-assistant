import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import 'database_service.dart';
import 'client_repository.dart';
import 'project_repository.dart';
import 'task_repository.dart';
import 'payment_repository.dart';
import 'invoice_repository.dart';

class BackupService {
  final ClientRepository _clientRepo;
  final ProjectRepository _projectRepo;
  final TaskRepository _taskRepo;
  final PaymentRepository _paymentRepo;
  final InvoiceRepository _invoiceRepo;

  BackupService({
    required ClientRepository clientRepo,
    required ProjectRepository projectRepo,
    required TaskRepository taskRepo,
    required PaymentRepository paymentRepo,
    required InvoiceRepository invoiceRepo,
  })  : _clientRepo = clientRepo,
        _projectRepo = projectRepo,
        _taskRepo = taskRepo,
        _paymentRepo = paymentRepo,
        _invoiceRepo = invoiceRepo;

  /// Export all data to a JSON file and share it
  Future<void> exportBackup() async {
    final data = {
      'backup_version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'clients': _clientRepo.getAll().map((c) => c.toJson()).toList(),
      'projects': _projectRepo.getAll().map((p) => p.toJson()).toList(),
      'tasks': _taskRepo.getAll().map((t) => t.toJson()).toList(),
      'payments': _paymentRepo.getAll().map((p) => p.toJson()).toList(),
      'invoices': _invoiceRepo.getAll().map((i) => i.toJson()).toList(),
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

      // Validate backup format — must have at least V1 fields
      if (!data.containsKey('clients') ||
          !data.containsKey('projects') ||
          !data.containsKey('tasks')) {
        return false;
      }

      final version = data['backup_version'] as int? ?? 1;

      // Parse core data (V1 + V2 compatible)
      final clients = (data['clients'] as List)
          .map((c) => Client.fromJson(c as Map<String, dynamic>))
          .toList();
      final projects = (data['projects'] as List)
          .map((p) => Project.fromJson(p as Map<String, dynamic>))
          .toList();
      // Task.fromJson auto-migrates old statuses (invoiced→done, paid→delivered)
      final tasks = (data['tasks'] as List)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList();

      // Parse V2 data if available
      final payments = version >= 2 && data.containsKey('payments')
          ? (data['payments'] as List)
              .map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList()
          : <Payment>[];

      final invoices = version >= 2 && data.containsKey('invoices')
          ? (data['invoices'] as List)
              .map((i) => Invoice.fromJson(i as Map<String, dynamic>))
              .toList()
          : <Invoice>[];

      // Clear existing data
      await _clientRepo.clearAll();
      await _projectRepo.clearAll();
      await _taskRepo.clearAll();
      await _paymentRepo.clearAll();
      await _invoiceRepo.clearAll();

      // Restore data
      await _clientRepo.addAll(clients);
      await _projectRepo.addAll(projects);
      await _taskRepo.addAll(tasks);
      await _paymentRepo.addAll(payments);
      await _invoiceRepo.addAll(invoices);

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
