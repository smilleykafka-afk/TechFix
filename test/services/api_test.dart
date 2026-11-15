import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techfix/services/api_client.dart';
import 'package:techfix/services/auth_service.dart';
import 'package:techfix/services/resource_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() async {
    await AuthService.instance.clear();
    ApiClient.instance.client = http.Client();
  });
  test(
    'login stores token, resource requests use bearer auth, logout clears it',
    () async {
      ApiClient.instance.client = MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          expect(jsonDecode(request.body)['email'], 'ana@example.com');
          return http.Response(
            jsonEncode({
              'token': 'test-token',
              'user': {
                'id': 1,
                'name': 'Ana',
                'email': 'ana@example.com',
                'role': 'employee',
              },
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        expect(request.url.queryParameters['search'], 'Ana');
        return http.Response(
          jsonEncode([
            {'id': 3, 'name': 'Ana'},
          ]),
          200,
        );
      });
      await AuthService.instance.authenticate('ana@example.com', 'secret123');
      expect(
        await AuthService.instance.storage.read(key: 'token'),
        'test-token',
      );
      expect(AuthService.instance.user!.isAdmin, isFalse);
      final records = await const CustomerService().list(search: 'Ana');
      expect(records.single.id, 3);
      expect(records.single.toJson()['name'], 'Ana');
      await AuthService.instance.logout();
      expect(ApiClient.instance.token, isNull);
      expect(AuthService.instance.user, isNull);
      expect(await AuthService.instance.storage.read(key: 'token'), isNull);
    },
  );
  test(
    'validation messages surface and expired tokens clear the session',
    () async {
      ApiClient.instance.client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'errors': {
              'phone': ['Phone is required.'],
            },
          }),
          422,
        ),
      );
      await expectLater(
        const CustomerService().save({}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Phone is required.',
          ),
        ),
      );
      ApiClient.instance.token = 'expired';
      ApiClient.instance.client = MockClient(
        (_) async => http.Response('{"message":"Unauthenticated."}', 401),
      );
      await expectLater(
        const CustomerService().list(),
        throwsA(isA<ApiException>()),
      );
      expect(ApiClient.instance.token, isNull);
    },
  );
  test('malformed server replies become readable API errors', () async {
    ApiClient.instance.client = MockClient(
      (_) async => http.Response('<html>Error</html>', 500),
    );
    await expectLater(
      const CustomerService().list(),
      throwsA(isA<ApiException>()),
    );
  });
}
