final bdPhoneRegExp = RegExp(r'^01[3-9]\d{8}$');

/// Rejects 11111, 12345, 54321 and similar obvious PINs.
bool isWeakPin(String pin) =>
    pin.split('').toSet().length == 1 ||
    '0123456789'.contains(pin) ||
    '9876543210'.contains(pin);
