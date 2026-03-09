import 'package:hive/hive.dart';

part 'invoice.g.dart';

@HiveType(typeId: 4)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int invoiceNumber;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  List<String> taskIds;

  @HiveField(4)
  double subtotal;

  @HiveField(5)
  double discount;

  @HiveField(6)
  double total;

  @HiveField(7)
  String status; // draft, sent, paid, cancelled

  @HiveField(8)
  DateTime issuedAt;

  @HiveField(9)
  DateTime? paidAt;

  @HiveField(10)
  String notes;

  @HiveField(11)
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.taskIds,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.status = 'draft',
    required this.issuedAt,
    this.paidAt,
    this.notes = '',
    required this.createdAt,
  });

  Invoice copyWith({
    int? invoiceNumber,
    List<String>? taskIds,
    double? subtotal,
    double? discount,
    double? total,
    String? status,
    DateTime? issuedAt,
    DateTime? paidAt,
    String? notes,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId,
      taskIds: taskIds ?? this.taskIds,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'clientId': clientId,
        'taskIds': taskIds,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'status': status,
        'issuedAt': issuedAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        invoiceNumber: json['invoiceNumber'] as int,
        clientId: json['clientId'] as String,
        taskIds: (json['taskIds'] as List).cast<String>(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        status: json['status'] as String? ?? 'draft',
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'] as String)
            : null,
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
