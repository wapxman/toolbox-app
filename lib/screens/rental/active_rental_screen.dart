import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'extend_screen.dart';

class ActiveRentalScreen extends StatelessWidget {
  final String toolName;
  final int days;
  final int totalPrice;
  final String boxName;

  const ActiveRentalScreen({
    super.key,
    required this.toolName,
    this.days = 3,
    this.totalPrice = 192000,
    this.boxName = 'Taketool #1',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активная аренда'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(Icons.build, color: AppTheme.textHint, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(toolName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(boxName,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: const Text('Активна',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A6FB5))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time remaining
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Text('Осталось',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('2 дня 14 часов',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      minHeight: 6,
                      backgroundColor: AppTheme.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Начало: 7 апр, 14:00',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textHint)),
                      Text('Конец: 10 апр, 14:00',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details
            const Text('Детали аренды',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _detailRow('Срок', '$days ${AppConstants.daysWord(days)}'),
            _detailRow('Стоимость', AppConstants.formatPrice(totalPrice)),
            _detailRow('Оплачено', AppConstants.formatPrice(totalPrice)),
            _detailRow('Способ оплаты', 'Payme'),
            _detailRow('Бокс', boxName),
            const SizedBox(height: 24),

            // Extend button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExtendScreen(
                      toolName: toolName,
                      currentDays: days,
                      pricePerDay: 80000,
                    ),
                  ),
                );
              },
              child: const Text('Продлить аренду'),
            ),
            const SizedBox(height: 10),

            // Return button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showReturnDialog(context);
                },
                child: const Text('Вернуть инструмент'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Возврат инструмента',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Верните $toolName в любой бокс Taketool.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              '1. Подойдите к боксу\n2. Отсканируйте QR-код\n3. Положите инструмент в ячейку\n4. Закройте дверцу',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
