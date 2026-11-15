import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techfix/core/theme/app_theme.dart';
import 'package:techfix/models/app_user.dart';
import 'package:techfix/screens/auth/auth_screen.dart';
import 'package:techfix/screens/home/home_screen.dart';
import 'package:techfix/screens/resources/resource_list_screen.dart';
import 'package:techfix/services/api_client.dart';
import 'package:techfix/services/auth_service.dart';

void main() {
  testWidgets(
    'screens render loaded, empty and error states and save screenshots',
    (tester) async {
      await tester.runAsync(() async {
        final configFile = File('.dart_tool/package_config.json').absolute;
        final config = jsonDecode(await configFile.readAsString()) as Map;
        final package = (config['packages'] as List).cast<Map>().firstWhere(
          (p) => p['name'] == 'flutter',
        );
        final sdkRoot = Directory.fromUri(
          configFile.uri.resolve(package['rootUri'] as String),
        ).parent.parent.path;
        for (final font in {
          'Roboto': 'roboto-regular.ttf',
          'MaterialIcons': 'materialicons-regular.otf',
        }.entries) {
          final loader = FontLoader(font.key);
          loader.addFont(
            File(
              '$sdkRoot/bin/cache/artifacts/material_fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          );
          await loader.load();
        }
      });
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final original = ApiClient.instance.client;
      addTearDown(() {
        ApiClient.instance.client = original;
        AuthService.instance.user = null;
      });
      AuthService.instance.user = const AppUser(
        id: 1,
        name: 'Ana Silva',
        email: 'ana@example.com',
        role: 'admin',
      );
      var fail = false;
      ApiClient.instance.client = MockClient((request) async {
        if (fail) {
          return http.Response(
            jsonEncode({'message': 'Serviço indisponível'}),
            503,
          );
        }
        if (request.url.path.endsWith('dashboard')) {
          return http.Response(
            jsonEncode({
              'customers': 24,
              'devices': 31,
              'open_orders': 8,
              'completed_orders': 17,
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      Future<void> capture(Widget screen, String name) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/screenshots/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture(const AuthScreen(), 'login');
      expect(find.text('Entrar'), findsOneWidget);
      await capture(const HomeScreen(), 'dashboard');
      expect(find.text('24'), findsOneWidget);
      await capture(
        const ResourceListScreen(resource: 'clientes'),
        'customers_empty',
      );
      expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
      fail = true;
      await capture(
        const ResourceListScreen(key: ValueKey('error'), resource: 'clientes'),
        'connection_error',
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    },
  );
}
