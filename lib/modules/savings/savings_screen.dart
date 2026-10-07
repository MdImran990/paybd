import 'package:flutter/material.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/savings_goal.dart';
import '../../data/models/transaction.dart';
import 'savings_providers.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsProvider);
    return Scaffold(
      appBar: PayAppBar(title: const Text('Savings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _NewGoalDialog(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: SafeArea(
        child: goals.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_rounded,
                          size: 56, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Create a goal and save a little at a time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                itemCount: goals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
              ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Saved ${formatTaka(goal.savedMinor)} of ${formatTaka(goal.targetMinor)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add money',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/savings/add', extra: goal.name);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: goal.savedMinor > 0
                  ? () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        '/pay/confirm',
                        extra: PaymentRequest(
                          type: TxType.savingsWithdraw,
                          counterparty: goal.name,
                          amountMinor: goal.savedMinor,
                          feeMinor: 0,
                        ),
                      );
                    }
                  : null,
              child: const Text('Withdraw all to wallet'),
            ),
            TextButton(
              onPressed: goal.savedMinor == 0
                  ? () {
                      ref.read(savingsProvider.notifier).delete(goal.id);
                      Navigator.of(sheetContext).pop();
                    }
                  : null,
              child: Text(
                'Delete goal',
                style: TextStyle(
                  color: goal.savedMinor == 0
                      ? AppColors.error
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showActions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(goal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  Text('${(goal.progress * 100).round()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${formatTaka(goal.savedMinor)} of ${formatTaka(goal.targetMinor)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewGoalDialog extends ConsumerStatefulWidget {
  const _NewGoalDialog();

  @override
  ConsumerState<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends ConsumerState<_NewGoalDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final target = parseTakaToMinor(_target.text) ?? 0;
    final error =
        await ref.read(savingsProvider.notifier).create(_name.text, target);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('New savings goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Goal name (e.g. Eid trip)'),
          ),
          TextField(
            controller: _target,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,7}(\.\d{0,2})?$')),
            ],
            decoration: const InputDecoration(
              hintText: 'Target amount',
              prefixText: '৳ ',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _create, child: const Text('Create')),
      ],
    );
  }
}
