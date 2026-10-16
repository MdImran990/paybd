import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../i18n/tr.dart';
import 'floating_bubbles.dart';
import 'pay_app_bar.dart';

/// Page = pink header (with an optional white card sticking out of it) + body.
/// Same look as the login page, the menu and Home.
class PinkPage extends StatelessWidget {
  final Widget header;
  final Widget body;
  const PinkPage({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class PinkHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// White card that overlaps the bottom of the pink area (search box, summary...).
  final Widget? card;

  /// Height of [card], so the right amount of space is left for it.
  final double cardHeight;

  const PinkHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.card,
    this.cardHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hasCard = card != null;
    const overlap = 30.0; // how far the card sticks into the pink area
    final bottomPadding = hasCard ? overlap + 14 : 22.0;
    final space = hasCard ? (cardHeight - overlap) : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(child: FloatingBubbles()),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(4, top + 6, 12, bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BackButton(
                              color: Colors.white,
                              onPressed: () => goBackOrHome(context),
                            ),
                            Expanded(
                              child: Tr(title,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                            ?trailing,
                          ],
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 52, top: 2),
                            child: Tr(subtitle!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: space),
          ],
        ),
        if (hasCard) Positioned(left: 16, right: 16, bottom: 0, child: card!),
      ],
    );
  }
}

/// White rounded card with a soft shadow, used inside [PinkHeader].
class HeaderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const HeaderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
