import 'package:hive_flutter/hive_flutter.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../models/invoice.dart';

class DatabaseService {
  static const String clientsBoxName = 'clients';
  static const String projectsBoxName = 'projects';
  static const String tasksBoxName = 'tasks';
  static const String paymentsBoxName = 'payments';
  static const String invoicesBoxName = 'invoices';
  static const String settingsBoxName = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(InvoiceAdapter());

    await Hive.openBox<Client>(clientsBoxName);
    await Hive.openBox<Project>(projectsBoxName);
    await Hive.openBox<Task>(tasksBoxName);
    await Hive.openBox<Payment>(paymentsBoxName);
    await Hive.openBox<Invoice>(invoicesBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<Client> get clientsBox => Hive.box<Client>(clientsBoxName);
  static Box<Project> get projectsBox => Hive.box<Project>(projectsBoxName);
  static Box<Task> get tasksBox => Hive.box<Task>(tasksBoxName);
  static Box<Payment> get paymentBox => Hive.box<Payment>(paymentsBoxName);
  static Box<Invoice> get invoiceBox => Hive.box<Invoice>(invoicesBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
