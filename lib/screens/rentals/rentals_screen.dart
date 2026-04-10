import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  final _api = ApiService();
  List<dynamic> _rentals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    try {
      final rentals = await _api.getActiveRentals();
      if (mounted) setState(() { _rentals = rentals; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои аренды')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _rentals.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.build_circle_outlined, size: 64, color: AppTheme.textHint),
                const SizedBox(height: 12),
                Text('Нет активных аренд', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('Найдите бокс и арендуйте инструмент',
                  style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
              ],
            ))
          : RefreshIndicator(
              onRefresh: _loadRentals,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _rentals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _rentalCard(_rentals[i]),
              ),
            ),
    );
  }

  Widget _rentalCard(Map<String, dynamic> rental) {
    final tool = rental['tools'] as Map<String, dynamic>? ?? {};
    final name = tool['name'] ?? 'Инструмент';
    final status = rental['status'] ?? 'active';
    final days = rental['days'] ?? 0;
    final expectedEnd = rental['expected_end'] != null
      ? DateTime.tryParse(rental['expected_end'])
      : null;
    final isOverdue = status == 'overdue';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: isOverdue ? AppTheme.error.withOpacity(0.3) : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFDE8E8) : const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(isOverdue ? 'Просрочена' : 'Активна',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isOverdue ? AppTheme.error : const Color(0xFF1A6FB5))),
            ),
          ]),
          const SizedBox(height: 8),
          Text('$days дн. • до ${expectedEnd != null ? '${expectedEnd.day}.${expectedEnd.month.toString().padLeft(2, '0')}' : '—'}',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
