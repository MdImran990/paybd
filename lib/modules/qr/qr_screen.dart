import 'package:flutter/material.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
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
      child: Scaffold(
        appBar: PayAppBar(
          title: const Tr('QR Pay'),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [Tab(text: tr('My QR')), Tab(text: tr('Scan'))],
          ),
        ),
        // Tabs are built only when shown, so the camera runs only on the Scan tab.
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [_MyQrTab(), _ScanTab()],
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
  final _amountText = ValueNotifier<String>('');

  @override
  void dispose() {
    _amount.dispose();
    _amountText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(sessionPhoneProvider) ?? '';
    final limits = WalletLimits.of(TxType.sent);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: staggered([
          ValueListenableBuilder<String>(
            valueListenable: _amountText,
            builder: (_, text, _) {
              final minor = parseTakaToMinor(text);
              final amountOk =
                  minor != null && minor >= limits.min && minor <= limits.max;
              final data = QrPayload(
                phone: phone,
                amountMinor: amountOk ? minor : null,
              ).toQrString();
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: QrImageView(
                      data: data,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
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
          const SizedBox(height: 18),
          Tr(phone,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
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
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: const Tr('Request an amount (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,5}(\.\d{0,2})?$')),
            ],
            onChanged: (v) => _amountText.value = v,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '৳ ',
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
            ),
          ),
        ]),
      ),
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
