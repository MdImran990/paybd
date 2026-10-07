import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';
import '../wallet/wallet_providers.dart';

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

/// One form for Send Money, Cash Out, Add Money and Mobile Recharge.
class PaymentFormScreen extends ConsumerStatefulWidget {
  final TxType type;
  final String title;

  /// null = no recipient field (Add Money).
  final String? recipientLabel;
  final bool blockSelf;

  /// false = account / meter number instead of a mobile number (Pay Bill).
  final bool recipientIsPhone;
  final List<int> quickAmounts;

  /// Optional chips (mobile operator, or where the money comes from).
  final String? noteLabel;
  final List<String> noteOptions;
  final String? Function(String phone)? suggestNote;

  /// Prefill (for example from a scanned QR code).
  final String? initialPhone;
  final int? initialAmountMinor;

  /// Preselected chip (for example the savings goal).
  final String? initialNote;

  const PaymentFormScreen({
    super.key,
    required this.type,
    required this.title,
    this.recipientLabel,
    this.blockSelf = false,
    this.recipientIsPhone = true,
    this.quickAmounts = const [100, 500, 1000, 2000],
    this.noteLabel,
    this.noteOptions = const [],
    this.suggestNote,
    this.initialPhone,
    this.initialAmountMinor,
    this.initialNote,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = ValueNotifier<String?>(null);
  final _error = ValueNotifier<String?>(null);
  final _valid = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);
  bool _noteTouched = false;

  bool get _hasRecipient => widget.recipientLabel != null;

  @override
  void initState() {
    super.initState();
    final phone = widget.initialPhone;
    final amount = widget.initialAmountMinor;
    if (phone != null) _phone.text = phone;
    if (amount != null) {
      final paisa = amount % 100;
      _amount.text = paisa == 0
          ? '${amount ~/ 100}'
          : '${amount ~/ 100}.${paisa.toString().padLeft(2, '0')}';
    }
    if (widget.initialNote != null) {
      _note.value = widget.initialNote;
      _noteTouched = true;
    }
    if (phone != null || amount != null || widget.initialNote != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revalidate();
      });
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    _error.dispose();
    _valid.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String phone) {
    if (widget.suggestNote != null && !_noteTouched) {
      _note.value = widget.suggestNote!(phone);
    }
    _revalidate();
  }

  void _revalidate() {
    final limits = WalletLimits.of(widget.type);
    String? error;
    var ok = true;

    if (_hasRecipient) {
      final phone = _phone.text;
      final recipientOk = widget.recipientIsPhone
          ? bdPhoneRegExp.hasMatch(phone)
          : RegExp(r'^\d{6,20}$').hasMatch(phone);
      if (!recipientOk) {
        ok = false;
      } else if (widget.blockSelf && phone == ref.read(sessionPhoneProvider)) {
        error = "You can't send money to yourself.";
        ok = false;
      }
    }

    if (widget.noteOptions.isNotEmpty && _note.value == null) ok = false;

    final minor = parseTakaToMinor(_amount.text);
    if (minor == null || minor == 0) {
      ok = false;
    } else if (minor < limits.min) {
      error ??= 'Minimum amount is ${formatTaka(limits.min)}.';
      ok = false;
    } else if (minor > limits.max) {
      error ??= 'Maximum per transaction is ${formatTaka(limits.max)}.';
      ok = false;
    } else if (widget.type.debitsWallet) {
      final balance = ref.read(walletProvider).value?.balanceMinor;
      if (balance != null && minor > balance) {
        error ??= 'Insufficient balance.';
        ok = false;
      }
    }

    _error.value = error;
    _valid.value = ok;
  }

  /// Last few people / accounts used for this kind of payment.
  List<String> _recents(WidgetRef ref) {
    final txs = ref.watch(walletProvider).value?.transactions ??
        const <Transaction>[];
    final seen = <String>[];
    for (final t in txs) {
      if (t.type == widget.type &&
          t.counterparty.isNotEmpty &&
          !seen.contains(t.counterparty)) {
        seen.add(t.counterparty);
      }
      if (seen.length >= 4) break;
    }
    return seen;
  }

  void _setQuick(int taka) {
    _amount.text = taka.toString();
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    _revalidate();
  }

  Future<void> _next() async {
    final minor = parseTakaToMinor(_amount.text)!;
    _loading.value = true;
    try {
      final fee =
          await ref.read(walletRepositoryProvider).quoteFee(widget.type, minor);
      final balance = ref.read(walletProvider).value?.balanceMinor;
      if (widget.type.debitsWallet && balance != null && minor + fee > balance) {
        _error.value =
            'Insufficient balance (including ${formatTaka(fee)} fee).';
        return;
      }
      final request = PaymentRequest(
        type: widget.type,
        counterparty: _hasRecipient ? _phone.text : (_note.value ?? ''),
        note: _hasRecipient ? _note.value : null,
        amountMinor: minor,
        feeMinor: fee,
      );
      if (mounted) context.push('/pay/confirm', extra: request);
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                      if (_hasRecipient) ...[
                        Text(widget.recipientLabel!,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(widget.recipientIsPhone ? 11 : 20),
                          ],
                          onChanged: _onPhoneChanged,
                          decoration: _decoration(
                            hint: widget.recipientIsPhone
                                ? '01XXXXXXXXX'
                                : 'Account or meter number',
                            prefix: Icon(widget.recipientIsPhone
                                ? Icons.phone_android_rounded
                                : Icons.receipt_long_rounded),
                          ),
                        ),
                        Consumer(builder: (_, ref, _) {
                          final recents = _recents(ref);
                          if (recents.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final r in recents)
                                  ActionChip(
                                    label: Text(r),
                                    backgroundColor: AppColors.panel,
                                    side: BorderSide.none,
                                    onPressed: () {
                                      _phone.text = r;
                                      _phone.selection = TextSelection.collapsed(
                                          offset: r.length);
                                      _onPhoneChanged(r);
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 22),
                      ],
                      if (widget.noteOptions.isNotEmpty) ...[
                        Text(widget.noteLabel ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<String?>(
                          valueListenable: _note,
                          builder: (_, selected, _) => Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              for (final o in widget.noteOptions)
                                ChoiceChip(
                                  label: Text(o),
                                  selected: selected == o,
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    color: selected == o
                                        ? Colors.white
                                        : AppColors.text,
                                  ),
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.panel,
                                  side: BorderSide.none,
                                  onSelected: (_) {
                                    _noteTouched = true;
                                    _note.value = o;
                                    _revalidate();
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      const Text('Amount',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        autofocus: !_hasRecipient,
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
                                        color: AppColors.error, fontSize: 13)),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          for (final v in widget.quickAmounts)
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
                valueListenable: _loading,
                builder: (_, loading, _) => ValueListenableBuilder<bool>(
                  valueListenable: _valid,
                  builder: (_, valid, _) => PrimaryButton(
                    label: 'Next',
                    loading: loading,
                    onPressed: valid ? _next : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
