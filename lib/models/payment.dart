import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  String? projectId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String method; // cash, instapay, bank_transfer, vodafone_cash, other

  @HiveField(6)
  String notes;

  @HiveField(7)
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.clientId,
    this.projectId,
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.notes = '',
    required this.createdAt,
  });

  Payment copyWith({
    String? clientId,
    String? projectId,
    double? amount,
    DateTime? date,
    String? method,
    String? notes,
  }) {
    return Payment(
      id: id,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'projectId': projectId,
        'amount': amount,
        'date': date.toIso8601String(),
        'method': method,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        projectId: json['projectId'] as String?,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        method: json['method'] as String? ?? 'cash',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
