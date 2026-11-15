import '../models/resource_record.dart';
import 'api_client.dart';

class ResourceService {
  final String resource;
  const ResourceService(this.resource);
  String get endpoint => resource == 'ordens' ? 'ordens-servico' : resource;
  Future<List<ResourceRecord>> list({
    String search = '',
    String status = '',
  }) async {
    final query = Uri(
      queryParameters: {'search': search, 'status': status},
    ).query;
    final List<dynamic> rows = await ApiClient.instance.request(
      'GET',
      '$endpoint?$query',
    );
    return rows
        .map((row) => ResourceRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ResourceRecord> get(int id) async => ResourceRecord.fromJson(
    await ApiClient.instance.request('GET', '$endpoint/$id'),
  );
  Future<void> save(Map<String, dynamic> values, {int? id}) async {
    await ApiClient.instance.request(
      id == null ? 'POST' : 'PUT',
      id == null ? endpoint : '$endpoint/$id',
      values,
    );
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.request('DELETE', '$endpoint/$id');
  }
}

class CustomerService extends ResourceService {
  const CustomerService() : super('clientes');
}

class DeviceService extends ResourceService {
  const DeviceService() : super('aparelhos');
}

class RepairOrderService extends ResourceService {
  const RepairOrderService() : super('ordens');
}

class EmployeeService extends ResourceService {
  const EmployeeService() : super('users');
}

class PartService extends ResourceService {
  const PartService() : super('parts');
}
