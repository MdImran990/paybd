import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pink_header.dart';
import 'notification_providers.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  // Remember which items were unread when the screen opened, then mark all as read.
  late final Set<String> _unreadIds;

  @override
  void initState() {
    super.initState();
    _unreadIds = {
      for (final n in ref.read(notificationsProvider))
        if (!n.read) n.id,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);
    return PinkPage(
      header: PinkHeader(
        title: 'Inbox',
        cardHeight: 84,
        card: HeaderCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.mail_outline_rounded,
                  label: 'Messages',
                  value: items.length,
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFEDEDF3)),
              Expanded(
                child: _Stat(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'New',
                  value: _unreadIds.length,
                ),
              ),
            ],
          ),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 56, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Tr('No messages yet',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                final isNew = _unreadIds.contains(n.id);
                return FadeSlideIn(
                  index: i < 8 ? i : 0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: softShadow,
                      border: isNew
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.notifications_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Tr(n.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Tr(n.body,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              Tr(formatDateTime(n.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        if (isNew)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: CircleAvatar(
                                radius: 4,
                                backgroundColor: AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Tr('$v',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            Tr(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
