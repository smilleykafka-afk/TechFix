import 'package:flutter_test/flutter_test.dart';
import 'package:techfix/core/utils/validators.dart';

void main() {
  test('email, password and confirmation validation', () {
    expect(Validators.email('ana@example.com'), isNull);
    expect(Validators.email('invalid'), isNotNull);
    expect(Validators.password('short'), isNotNull);
    expect(Validators.passwordConfirmation('different', 'password'), isNotNull);
  });
}
