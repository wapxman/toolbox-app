import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../rental/active_rental_screen.dart';

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rentals = [
      _RentalItem('Дрель Bosch GSB 13 RE', 'ToolBox #1', 3, 192000, '2 дня 14ч', 'active'),
      _RentalItem('Перфоратор Bosch GBH 2-26', 'ToolBox #1', 2, 160000, 'Просрочка 1 день', 'overdue'),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Мои аренды',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: rentals.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rentals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = rentals[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveRentalScreen(
                                toolName: r.name,
                                days: r.days,
                                totalPrice: r.price,
                                boxName: r.box,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: r.status == 'overdue'
                                  ? AppTheme.error.withOpacity(0.3)
                                  : AppTheme.borderLight,
                            ),
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
                                child: Icon(Icons.build,
                                    color: AppTheme.textHint, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(r.box,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          r.status == 'overdue'
                                              ? Icons.warning_amber_rounded
                                              : Icons.access_time,
                                          size: 13,
                                          color: r.status == 'overdue'
                                              ? AppTheme.error
                                              : AppTheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r.remaining,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: r.status == 'overdue'
                                                ? AppTheme.error
                                                : AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 18, color: AppTheme.textHint),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 12),
          Text('Нет активных аренд',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('Отсканируйте QR-код на боксе,\nчтобы арендовать инструмент',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textHint, height: 1.5)),
        ],
      ),
    );
  }
}

class _RentalItem {
  final String name, box, remaining, status;
  final int days, price;
  _RentalItem(this.name, this.box, this.days, this.price, this.remaining, this.status);
}
