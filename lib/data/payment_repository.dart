import 'package:hive/hive.dart';
import '../models/payment.dart';
import 'database_service.dart';

class PaymentRepository {
  Box<Payment> get _box => DatabaseService.paymentBox;

  List<Payment> getAll() => _box.values.toList();

  List<Payment> getByClient(String clientId) =>
      _box.values.where((p) => p.clientId == clientId).toList();

  List<Payment> getByProject(String projectId) =>
      _box.values.where((p) => p.projectId == projectId).toList();

  Future<void> add(Payment payment) async {
    await _box.put(payment.id, payment);
  }

  Future<void> addAll(List<Payment> payments) async {
    final map = {for (var p in payments) p.id: p};
    await _box.putAll(map);
  }

  Future<void> update(Payment payment) async {
    await _box.put(payment.id, payment);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByClientId(String clientId) async {
    final keys =
        _box.values.where((p) => p.clientId == clientId).map((p) => p.id);
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
