import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 1)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String description;

  @HiveField(4)
  String status; // active, completed, on-hold

  @HiveField(5)
  String currency; // EGP, USD

  @HiveField(6)
  final DateTime createdAt;

  Project({
    required this.id,
    required this.clientId,
    required this.name,
    this.description = '',
    this.status = 'active',
    this.currency = 'EGP',
    required this.createdAt,
  });

  Project copyWith({
    String? name,
    String? description,
    String? status,
    String? currency,
  }) {
    return Project(
      id: id,
      clientId: clientId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'clientId': clientId,
        'description': description,
        'status': status,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        currency: json['currency'] as String? ?? 'EGP',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
