/// UI talks only to this interface.
/// Today: MockAuthRepository. Later: ApiAuthRepository (real SMS OTP from server).
abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String code);
}

/// DEMO ONLY. Accepts the fixed code 123456. Never ship this to production.
class MockAuthRepository implements AuthRepository {
  static const demoCode = '123456';

  @override
  Future<void> sendOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return code == demoCode;
  }
}
