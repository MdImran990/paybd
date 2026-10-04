/// UI and providers talk only to this interface.
/// Today: MockWalletRepository. Later: ApiWalletRepository.
abstract class WalletRepository {
  Future<double> getBalance();
}

/// DEMO ONLY. This is not real money.
class MockWalletRepository implements WalletRepository {
  @override
  Future<double> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 16003.00;
  }
}
