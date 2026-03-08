import '../models/client.dart';
import 'database_service.dart';

class ClientRepository {
  final box = DatabaseService.clientsBox;

  List<Client> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Client? getById(String id) {
    try {
      return box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Client client) async {
    await box.put(client.id, client);
  }

  Future<void> update(Client client) async {
    await box.put(client.id, client);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  Future<void> clearAll() async {
    await box.clear();
  }

  Future<void> addAll(List<Client> clients) async {
    for (final client in clients) {
      await box.put(client.id, client);
    }
  }
}
