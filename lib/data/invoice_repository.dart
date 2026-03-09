import 'package:hive/hive.dart';
import '../models/invoice.dart';
import 'database_service.dart';

class InvoiceRepository {
  Box<Invoice> get _box => DatabaseService.invoiceBox;

  List<Invoice> getAll() => _box.values.toList();

  List<Invoice> getByClient(String clientId) =>
      _box.values.where((i) => i.clientId == clientId).toList();

  int getNextInvoiceNumber() {
    if (_box.isEmpty) return 1;
    final maxNum =
        _box.values.map((i) => i.invoiceNumber).reduce((a, b) => a > b ? a : b);
    return maxNum + 1;
  }

  Future<void> add(Invoice invoice) async {
    await _box.put(invoice.id, invoice);
  }

  Future<void> addAll(List<Invoice> invoices) async {
    final map = {for (var i in invoices) i.id: i};
    await _box.putAll(map);
  }

  Future<void> update(Invoice invoice) async {
    await _box.put(invoice.id, invoice);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByClientId(String clientId) async {
    final keys =
        _box.values.where((i) => i.clientId == clientId).map((i) => i.id);
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
