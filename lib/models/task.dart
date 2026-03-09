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
  String status; // pending, in_progress, review, done, delivered

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  String priority; // low, medium, high, urgent

  @HiveField(9)
  DateTime? completedAt;

  @HiveField(10)
  DateTime? deliveredAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.cost = 0.0,
    required this.date,
    this.status = 'pending',
    required this.createdAt,
    this.priority = 'medium',
    this.completedAt,
    this.deliveredAt,
  });

  Task copyWith({
    String? title,
    String? description,
    double? cost,
    DateTime? date,
    String? status,
    String? priority,
    DateTime? completedAt,
    DateTime? deliveredAt,
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
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
        'priority': priority,
        'completedAt': completedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    // Migrate old statuses
    String rawStatus = json['status'] as String? ?? 'pending';
    if (rawStatus == 'invoiced') rawStatus = 'done';
    if (rawStatus == 'paid') rawStatus = 'delivered';

    return Task(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      cost: (json['cost'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: rawStatus,
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority: json['priority'] as String? ?? 'medium',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
    );
  }
}
