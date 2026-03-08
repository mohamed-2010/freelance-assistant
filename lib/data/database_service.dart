import 'package:hive_flutter/hive_flutter.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/task.dart';

class DatabaseService {
  static const String clientsBoxName = 'clients';
  static const String projectsBoxName = 'projects';
  static const String tasksBoxName = 'tasks';
  static const String settingsBoxName = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());

    await Hive.openBox<Client>(clientsBoxName);
    await Hive.openBox<Project>(projectsBoxName);
    await Hive.openBox<Task>(tasksBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<Client> get clientsBox => Hive.box<Client>(clientsBoxName);
  static Box<Project> get projectsBox => Hive.box<Project>(projectsBoxName);
  static Box<Task> get tasksBox => Hive.box<Task>(tasksBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
