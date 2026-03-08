import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String contact;

  @HiveField(3)
  String notes;

  @HiveField(4)
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    this.contact = '',
    this.notes = '',
    required this.createdAt,
  });

  Client copyWith({
    String? name,
    String? contact,
    String? notes,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contact,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String,
        contact: json['contact'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
