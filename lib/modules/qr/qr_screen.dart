import 'package:flutter/material.dart';
import '../../core/widgets/pink_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pink_auth_page.dart';
import '../../core/widgets/pay_keypad.dart';
import '../../core/utils/numeric_input.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';
import 'qr_payload.dart';

class QrScreen extends StatelessWidget {
  /// 0 = My QR, 1 = Scan
  final int initialTab;
  const QrScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: PinkPage(
        header: const PinkHeader(title: 'QR Pay'),
        body: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [Tab(text: tr('My QR')), Tab(text: tr('Scan'))],
            ),
            // Tabs are built only when shown, so the camera runs only on the Scan tab.
            const Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [_MyQrTab(), _ScanTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- My QR ----------------

class _MyQrTab extends ConsumerStatefulWidget {
  const _MyQrTab();

  @override
  ConsumerState<_MyQrTab> createState() => _MyQrTabState();
}

class _MyQrTabState extends ConsumerState<_MyQrTab> {
  final _amount = TextEditingController();
  final _focus = FocusNode();
  final _amountText = ValueNotifier<String>('');

  @override
  void dispose() {
    _amount.dispose();
    _focus.dispose();
    _amountText.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (key == 'next') return;
    if (applyKey(_amount, key, decimal: true, maxInt: 5, maxDecimals: 2)) {
      _amountText.value = _amount.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(sessionPhoneProvider) ?? '';
    final limits = WalletLimits.of(TxType.sent);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              children: staggered([
                ValueListenableBuilder<String>(
                  valueListenable: _amountText,
                  builder: (_, text, _) {
                    final minor = parseTakaToMinor(text);
                    final amountOk = minor != null &&
                        minor >= limits.min &&
                        minor <= limits.max;
                    final data = QrPayload(
                      phone: phone,
                      amountMinor: amountOk ? minor : null,
                    ).toQrString();
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8)),
                            ],
                          ),
                          child: QrImageView(
                            data: data,
                            size: 190,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Tr(
                          amountOk
                              ? 'Request ${formatTaka(minor)}'
                              : 'Anyone can scan this to pay you',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        if (text.isNotEmpty && !amountOk)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Tr(
                              'Amount must be ${formatTaka(limits.min)} to ${formatTaka(limits.max)}.',
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Tr(phone,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: phone));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Tr('Number copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Tr('Copy number'),
                ),
                const SizedBox(height: 6),
                AuthCard(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _amountText,
                    builder: (_, _, _) => PinkField(
                      label: 'Request an amount (optional)',
                      controller: _amount,
                      focus: _focus,
                      hint: '0.00',
                      prefix: const Text('৳',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        PayKeypad(kind: KeypadKind.decimal, onKey: _onKey),
      ],
    );
  }
}

// ---------------- Scan ----------------

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  bool _handled = false;
  DateTime _lastWarning = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final payload = QrPayload.tryParse(raw);
      if (payload != null) {
        _handled = true;
        HapticFeedback.mediumImpact();
        await context.push('/send', extra: payload);
        // Back from the payment flow: allow scanning again.
        _handled = false;
        return;
      }

      final now = DateTime.now();
      if (now.difference(_lastWarning) > const Duration(seconds: 3)) {
        _lastWarning = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Tr('This is not a PayBD QR code.')),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(onDetect: _onDetect),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: IgnorePointer(
            child: Tr(
              'Point the camera at a PayBD QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
