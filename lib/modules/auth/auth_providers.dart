import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/pin_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

final pinRepositoryProvider = Provider<PinRepository>(
  (ref) => MockPinRepository(),
);

/// Phone number of the logged-in user (null when logged out).
class SessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPhone(String phone) => state = phone;
}

final sessionPhoneProvider =
    NotifierProvider<SessionNotifier, String?>(SessionNotifier.new);
