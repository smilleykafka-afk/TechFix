import 'package:flutter_test/flutter_test.dart';
import 'package:techfix/app.dart';

void main() {
  testWidgets('unauthenticated users are sent to login', (tester) async {
    await tester.pumpWidget(const TechFixApp());
    await tester.pumpAndSettle();
    expect(find.text('TechFix'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Cadastrar funcionário'), findsOneWidget);
  });
}
