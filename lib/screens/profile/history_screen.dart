import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      _Rental('Дрель Bosch GSB 13 RE', 'Taketool #1', 3, 192000, 'active'),
      _Rental('Шуруповёрт Makita DF331D', 'Taketool #2', 1, 80000, 'completed'),
      _Rental('Болгарка DeWalt DWE4057', 'Taketool #1', 7, 364000, 'completed'),
      _Rental('Перфоратор Bosch GBH 2-26', 'Taketool #1', 2, 160000, 'overdue'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('История аренд')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = history[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.toolName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    _statusPill(r.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(r.boxName,
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text('${r.days} ${AppConstants.daysWord(r.days)}',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(AppConstants.formatPrice(r.price),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'active':
        bg = const Color(0xFFE8F4FD);
        fg = const Color(0xFF1A6FB5);
        label = 'Активна';
        break;
      case 'overdue':
        bg = const Color(0xFFFDE8E8);
        fg = AppTheme.error;
        label = 'Просрочена';
        break;
      default:
        bg = const Color(0xFFE6F7EE);
        fg = AppTheme.success;
        label = 'Завершена';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _Rental {
  final String toolName, boxName, status;
  final int days, price;
  _Rental(this.toolName, this.boxName, this.days, this.price, this.status);
}
