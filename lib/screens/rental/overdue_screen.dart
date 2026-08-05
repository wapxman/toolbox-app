import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class OverdueScreen extends StatelessWidget {
  final String toolName;
  final String boxName;
  final int overdueDays;
  final int penaltyPerDay;

  const OverdueScreen({
    super.key,
    required this.toolName,
    this.boxName = 'Taketool #1',
    this.overdueDays = 2,
    this.penaltyPerDay = 120000,
  });

  @override
  Widget build(BuildContext context) {
    final penalty = overdueDays * penaltyPerDay;

    return Scaffold(
      appBar: AppBar(title: const Text('Просрочка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 48, color: AppTheme.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Аренда просрочена!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC0392B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Просрочка: $overdueDays ${AppConstants.daysWord(overdueDays)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFC0392B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tool info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child:
                        Icon(Icons.build, color: AppTheme.textHint, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(toolName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(boxName,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Penalty calculation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Штраф за просрочку',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                      Text('×1.5 от дневной ставки',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textHint)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '$overdueDays ${AppConstants.daysWord(overdueDays)} × ${AppConstants.formatPrice(penaltyPerDay)}',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                      Text(AppConstants.formatPrice(penalty),
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('К оплате',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(AppConstants.formatPrice(penalty),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Верните инструмент как можно скорее.\nШтраф начисляется за каждый день просрочки.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textHint, height: 1.5),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Штраф оплачен. Верните инструмент в бокс.')),
                );
                Navigator.pop(context);
              },
              child: Text('Оплатить ${AppConstants.formatPrice(penalty)}'),
            ),
          ],
        ),
      ),
    );
  }
}
