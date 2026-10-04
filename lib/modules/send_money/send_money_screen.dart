import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';
import '../wallet/wallet_providers.dart';
import 'send_payload.dart';

InputDecoration _decoration({required String hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefix,
    filled: true,
    fillColor: AppColors.panel,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _error = ValueNotifier<String?>(null);
  final _valid = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _error.dispose();
    _valid.dispose();
    super.dispose();
  }

  void _revalidate() {
    final phone = _phone.text;
    String? error;
    var ok = true;

    if (!bdPhoneRegExp.hasMatch(phone)) {
      ok = false;
    } else if (phone == ref.read(sessionPhoneProvider)) {
      error = "You can't send money to yourself.";
      ok = false;
    }

    final minor = parseTakaToMinor(_amount.text);
    if (minor == null || minor == 0) {
      ok = false;
    } else if (minor < WalletLimits.minSendMinor) {
      error ??= 'Minimum amount is ${formatTaka(WalletLimits.minSendMinor)}.';
      ok = false;
    } else if (minor > WalletLimits.maxSendMinor) {
      error ??= 'Maximum per transaction is ${formatTaka(WalletLimits.maxSendMinor)}.';
      ok = false;
    } else {
      final balance = ref.read(walletProvider).value?.balanceMinor;
      if (balance != null && minor > balance) {
        error ??= 'Insufficient balance.';
        ok = false;
      }
    }

    _error.value = error;
    _valid.value = ok;
  }

  void _setQuick(int taka) {
    _amount.text = taka.toString();
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    _revalidate();
  }

  void _next() {
    final minor = parseTakaToMinor(_amount.text)!;
    context.push(
      '/send/confirm',
      extra: SendPayload(phone: _phone.text, amountMinor: minor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(builder: (_, ref, _) {
                        final bal =
                            ref.watch(walletProvider).value?.balanceMinor;
                        return Text(
                          bal == null
                              ? ' '
                              : 'Available balance: ${formatTaka(bal)}',
                          style: const TextStyle(color: AppColors.textMuted),
                        );
                      }),
                      const SizedBox(height: 24),
                      const Text('Recipient',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: (_) => _revalidate(),
                        decoration: _decoration(
                          hint: '01XXXXXXXXX',
                          prefix: const Icon(Icons.phone_android_rounded),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('Amount',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,5}(\.\d{0,2})?$')),
                        ],
                        onChanged: (_) => _revalidate(),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: _decoration(hint: '0.00').copyWith(
                          prefixText: '৳ ',
                          prefixStyle: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: _error,
                        builder: (_, e, _) => e == null
                            ? const SizedBox(height: 14)
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(e,
                                    style: const TextStyle(
                                        color: AppColors.pink, fontSize: 13)),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          for (final v in const [100, 500, 1000, 2000])
                            ActionChip(
                              label: Text('৳ $v'),
                              backgroundColor: AppColors.panel,
                              side: BorderSide.none,
                              onPressed: () => _setQuick(v),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _valid,
                builder: (_, valid, _) => PrimaryButton(
                  label: 'Next',
                  onPressed: valid ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
