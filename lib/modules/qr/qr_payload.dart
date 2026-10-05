import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';

/// What a PayBD QR code contains:  paybd://pay?phone=01712345678&amount=500.00
/// The amount is optional. A scanned QR is untrusted input: always validate it,
/// and the user still confirms everything with the PIN.
class QrPayload {
  final String phone;
  final int? amountMinor; // paisa

  const QrPayload({required this.phone, this.amountMinor});

  String toQrString() {
    final query = <String, String>{'phone': phone};
    final m = amountMinor;
    if (m != null && m > 0) {
      query['amount'] = '${m ~/ 100}.${(m % 100).toString().padLeft(2, '0')}';
    }
    return Uri(scheme: 'paybd', host: 'pay', queryParameters: query).toString();
  }

  /// Returns null if the text is not a valid PayBD payment QR.
  static QrPayload? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'paybd' || uri.host != 'pay') return null;

    final phone = uri.queryParameters['phone'];
    if (phone == null || !bdPhoneRegExp.hasMatch(phone)) return null;

    int? amount;
    final a = uri.queryParameters['amount'];
    if (a != null) {
      amount = parseTakaToMinor(a);
      if (amount == null) return null; // malformed amount: reject the whole QR
    }
    return QrPayload(phone: phone, amountMinor: amount);
  }
}
