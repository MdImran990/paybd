import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/modules/qr/qr_payload.dart';

void main() {
  test('round trip with amount', () {
    const p = QrPayload(phone: '01712345678', amountMinor: 50000);
    final parsed = QrPayload.tryParse(p.toQrString());
    expect(parsed, isNotNull);
    expect(parsed!.phone, '01712345678');
    expect(parsed.amountMinor, 50000);
  });

  test('round trip without amount', () {
    const p = QrPayload(phone: '01712345678');
    final parsed = QrPayload.tryParse(p.toQrString());
    expect(parsed!.amountMinor, isNull);
  });

  test('rejects foreign or malformed QR codes', () {
    expect(QrPayload.tryParse('https://example.com'), isNull);
    expect(QrPayload.tryParse('paybd://pay?phone=123'), isNull);
    expect(QrPayload.tryParse('paybd://pay?phone=01712345678&amount=abc'), isNull);
    expect(QrPayload.tryParse('hello'), isNull);
  });
}
