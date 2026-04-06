import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ExtendScreen extends StatefulWidget {
  final String toolName;
  final int currentDays;
  final int pricePerDay;

  const ExtendScreen({
    super.key,
    required this.toolName,
    required this.currentDays,
    required this.pricePerDay,
  });

  @override
  State<ExtendScreen> createState() => _ExtendScreenState();
}

class _ExtendScreenState extends State<ExtendScreen> {
  int _extraDays = 1;

  int get _newTotal => widget.currentDays + _extraDays;
  int get _extensionPrice => AppConstants.priceForDays(_newTotal) - AppConstants.priceForDays(widget.currentDays);

  void _setExtra(int d) {
    if (d >= 1 && d <= 30) setState(() => _extraDays = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Продление')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current rental info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.toolName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Текущий срок: ${widget.currentDays} ${AppConstants.daysWord(widget.currentDays)}',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Продлить на',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),

            // Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterBtn(Icons.remove, () => _setExtra(_extraDays - 1)),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text('$_extraDays',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600)),
                    Text(AppConstants.daysWord(_extraDays),
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(width: 24),
                _counterBtn(Icons.add, () => _setExtra(_extraDays + 1)),
              ],
            ),
            const SizedBox(height: 16),

            // Quick chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 3, 5, 7].map((d) {
                final active = _extraDays == d;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _setExtra(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text('+$d',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.white : AppTheme.textSecondary,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Price summary
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
                      Text('Новый срок',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      Text('$_newTotal ${AppConstants.daysWord(_newTotal)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (_newTotal >= 3) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Скидка',
                            style: TextStyle(fontSize: 13, color: AppTheme.success)),
                        Text(_newTotal >= 7 ? '−35%' : '−20%',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Доплата',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(AppConstants.formatPrice(_extensionPrice),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Аренда продлена!')),
                );
                Navigator.pop(context);
              },
              child: Text('Оплатить ${AppConstants.formatPrice(_extensionPrice)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
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
