import 'package:flutter/material.dart';
import '../i18n/tr.dart';
import '../../app/theme/app_colors.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const DetailRow(this.label, this.value, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tr(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Tr(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
