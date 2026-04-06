import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final String toolName;
  final int pricePerDay;
  final String boxName;

  const BookingScreen({
    super.key,
    required this.toolName,
    required this.pricePerDay,
    required this.boxName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _days = 1;

  int get _totalPrice => AppConstants.priceForDays(_days);

  String? get _discountLabel {
    if (_days >= 7) return '−35%';
    if (_days >= 3) return '−20%';
    return null;
  }

  int get _savedAmount {
    final full = _days * widget.pricePerDay;
    return full - _totalPrice;
  }

  void _setDays(int d) {
    if (d >= 1 && d <= 30) setState(() => _days = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool info
            Container(
              padding: const EdgeInsets.all(12),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(Icons.build, color: AppTheme.textHint, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.toolName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.boxName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Day selector
            const Text(
              'Срок аренды',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            // Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterButton(Icons.remove, () => _setDays(_days - 1)),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$_days',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppConstants.daysWord(_days),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _counterButton(Icons.add, () => _setDays(_days + 1)),
              ],
            ),
            const SizedBox(height: 16),

            // Quick day chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 3, 5, 7, 14].map((d) {
                final isActive = _days == d;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _setDays(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color:
                              isActive ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        '$d ${AppConstants.daysWord(d)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Price block
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
                      Text(
                        '$_days ${AppConstants.daysWord(_days)} × ${AppConstants.formatPrice(widget.pricePerDay)}',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Text(
                        AppConstants.formatPrice(
                            _days * widget.pricePerDay),
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (_discountLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Скидка ',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.success),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7EE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _discountLabel!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '−${AppConstants.formatPrice(_savedAmount)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppConstants.formatPrice(_totalPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Book button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      toolName: widget.toolName,
                      days: _days,
                      totalPrice: _totalPrice,
                    ),
                  ),
                );
              },
              child: const Text('Перейти к оплате'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 24),
      ),
    );
  }
}
