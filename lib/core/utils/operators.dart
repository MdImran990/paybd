const mobileOperators = [
  'Grameenphone',
  'Robi',
  'Banglalink',
  'Airtel',
  'Teletalk',
];

/// Guess the operator from the number prefix. Number portability means the guess
/// can be wrong, so the user can always change it.
String? operatorForPhone(String phone) {
  if (phone.length < 3) return null;
  return switch (phone.substring(0, 3)) {
    '017' || '013' => 'Grameenphone',
    '018' => 'Robi',
    '019' || '014' => 'Banglalink',
    '016' => 'Airtel',
    '015' => 'Teletalk',
    _ => null,
  };
}
