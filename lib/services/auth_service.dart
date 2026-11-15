import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_user.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  AuthService._() {
    ApiClient.instance.onUnauthorized = () {
      clear();
    };
  }
  static final instance = AuthService._();
  final storage = const FlutterSecureStorage();
  AppUser? user;
  Future<void> restore() async {
    try {
      ApiClient.instance.token = await storage.read(key: 'token');
      if (ApiClient.instance.token != null) {
        user = AppUser.fromJson(
          await ApiClient.instance.request('GET', 'profile'),
        );
      }
    } catch (_) {
      await clear();
    }
  }

  Future<void> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    final json = await ApiClient.instance
        .request('POST', name == null ? 'login' : 'register', {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
          if (name != null) 'password_confirmation': password,
        });
    final token = json['token'] as String;
    await storage.write(key: 'token', value: token);
    ApiClient.instance.token = token;
    user = AppUser.fromJson(json['user']);
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    user = AppUser.fromJson(
      await ApiClient.instance.request('PUT', 'profile', {
        'name': name,
        'email': email,
      }),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiClient.instance.request('POST', 'logout');
    await clear();
  }

  Future<void> clear() async {
    ApiClient.instance.token = null;
    user = null;
    notifyListeners();
    await storage.delete(key: 'token');
  }
}
