import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  double cost;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String status; // pending, invoiced, paid

  @HiveField(7)
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.cost = 0.0,
    required this.date,
    this.status = 'pending',
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    double? cost,
    DateTime? date,
    String? status,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'cost': cost,
        'date': date.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        cost: (json['cost'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
