import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../core/widgets/primary_button.dart';
import 'nominee_provider.dart';

const _relations = [
  'Spouse',
  'Father',
  'Mother',
  'Son',
  'Daughter',
  'Brother',
  'Sister',
  'Other',
];

class NomineeScreen extends ConsumerStatefulWidget {
  const NomineeScreen({super.key});

  @override
  ConsumerState<NomineeScreen> createState() => _NomineeScreenState();
}

class _NomineeScreenState extends ConsumerState<NomineeScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = ValueNotifier<String?>(null);
  final _valid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final n = ref.read(nomineeProvider);
    if (n != null) {
      _name.text = n.name;
      _phone.text = n.phone;
      _relation.value = n.relation;
    }
    _revalidate();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    _valid.dispose();
    super.dispose();
  }

  void _revalidate() {
    final nameOk = _name.text.trim().length >= 3;
    final relationOk = _relation.value != null;
    final phoneOk = _phone.text.isEmpty || bdPhoneRegExp.hasMatch(_phone.text);
    _valid.value = nameOk && relationOk && phoneOk;
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: tr(hint),
        counterText: '',
        filled: true,
        fillColor: AppColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ref.read(nomineeProvider.notifier).save(
          Nominee(
            name: _name.text.trim(),
            relation: _relation.value!,
            phone: _phone.text,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Tr('Nominee saved')));
    goBackOrHome(context);
  }

  Future<void> _remove() async {
    await ref.read(nomineeProvider.notifier).remove();
    if (mounted) goBackOrHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(nomineeProvider) != null;
    return Scaffold(
      appBar: const PayAppBar(title: Tr('Nominee information')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            FadeSlideIn(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Tr('Your nominee is saved only on this device.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 1,
              child: TextField(
                controller: _name,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _revalidate(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: _decoration('Nominee name'),
              ),
            ),
            const SizedBox(height: 18),
            const FadeSlideIn(
              index: 2,
              child: Tr('Relationship',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              index: 3,
              child: ValueListenableBuilder<String?>(
                valueListenable: _relation,
                builder: (_, selected, _) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _relations)
                      ChoiceChip(
                        label: Tr(r),
                        selected: selected == r,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.panel,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: selected == r ? Colors.white : AppColors.text,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          _relation.value = r;
                          _revalidate();
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              index: 4,
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (_) => _revalidate(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: _decoration('Nominee mobile number (optional)'),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              index: 5,
              child: ValueListenableBuilder<bool>(
                valueListenable: _valid,
                builder: (_, valid, _) => PrimaryButton(
                  label: 'Save nominee',
                  onPressed: valid ? _save : null,
                ),
              ),
            ),
            if (saved)
              Center(
                child: TextButton(
                  onPressed: _remove,
                  child: const Tr('Remove nominee',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
