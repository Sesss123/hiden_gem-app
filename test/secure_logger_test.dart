import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';

void main() {
  test('redacts sensitive values from telemetry text', () {
    const input = 'email=test@example.com phone=+94 77 123 4567 token=abc123 '
        'Bearer secret.jwt.value https://example.com/path?token=abc '
        '6.927100,79.861200 C:\\Users\\person\\secret.txt';

    final output = SecureLogger.redact(input);

    expect(output, isNot(contains('test@example.com')));
    expect(output, isNot(contains('+94 77 123 4567')));
    expect(output, isNot(contains('abc123')));
    expect(output, isNot(contains('secret.jwt.value')));
    expect(output, isNot(contains('6.927100')));
    expect(output, isNot(contains(r'C:\Users\person')));
    expect(output, contains('[REDACTED_EMAIL]'));
    expect(output, contains('[REDACTED_LOCATION]'));
  });
}
