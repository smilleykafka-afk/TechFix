import 'api_client.dart';

class DashboardService {
  Future<Map<String, dynamic>> load() async => Map<String, dynamic>.from(
    await ApiClient.instance.request('GET', 'dashboard'),
  );
}
