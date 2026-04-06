import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../rental/booking_screen.dart';

class ToolDetailScreen extends StatelessWidget {
  final String toolName;
  final String category;
  final int pricePerDay;
  final String boxName;

  const ToolDetailScreen({
    super.key,
    required this.toolName,
    required this.category,
    required this.pricePerDay,
    required this.boxName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инструмент'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool image placeholder
            Container(
              width: double.infinity,
              height: 220,
              color: AppTheme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build, size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and availability
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          toolName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7EE),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          'Свободен',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category,
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  // Price block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.formatPrice(pricePerDay),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'за 1 день',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        _discountRow('от 3 дней', '−20%',
                            AppConstants.formatPrice(AppConstants.priceForDays(3))),
                        const SizedBox(height: 6),
                        _discountRow('от 7 дней', '−35%',
                            AppConstants.formatPrice(AppConstants.priceForDays(7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Location
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 20, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                boxName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ТЦ Samarqand Darvoza, 2 этаж',
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
                  const SizedBox(height: 20),
                  // Specs
                  const Text(
                    'Характеристики',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _specRow('Мощность', '600 Вт'),
                  _specRow('Вес', '1.8 кг'),
                  _specRow('Макс. обороты', '2800 об/мин'),
                  _specRow('Патрон', '13 мм'),
                  const SizedBox(height: 28),
                  // Book button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(
                            toolName: toolName,
                            pricePerDay: pricePerDay,
                            boxName: boxName,
                          ),
                        ),
                      );
                    },
                    child: const Text('Забронировать'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountRow(String label, String discount, String total) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7EE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            discount,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ),
        const Spacer(),
        Text(
          total,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
