import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

/// История завершённых аренд (GET /rentals/history).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getRentalHistory();
      if (mounted) setState(() { _items = items; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? e.message : 'Не удалось загрузить историю';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История аренд')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _message(Icons.cloud_off_outlined, _error!)
              : _items.isEmpty
                  ? _message(Icons.history, 'Завершённых аренд пока нет')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _card(_items[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final tool = r['tools'] as Map<String, dynamic>? ?? {};
    final name = tool['name'] ?? 'Инструмент';
    final days = (r['days'] as num?)?.toInt() ?? 0;
    final price = (r['total_price'] as num?)?.toInt() ?? 0;
    final fee = (r['overdue_fee'] as num?)?.toInt() ?? 0;
    final started = DateTime.tryParse(r['started_at'] ?? '')?.toLocal();
    final ended = DateTime.tryParse(r['actual_end'] ?? '')?.toLocal();
    String d(DateTime? t) => t == null
        ? '—'
        : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

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
                child: Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              _pill(fee > 0 ? 'Со штрафом' : 'Завершена', fee > 0),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text('${d(started)} — ${d(ended)}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const Spacer(),
              Text('$days ${AppConstants.daysWord(days)}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.formatPrice(price) + (fee > 0 ? ' + штраф ${AppConstants.formatPrice(fee)}' : ''),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool warn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFDE8E8) : const Color(0xFFE6F7EE),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: warn ? AppTheme.error : AppTheme.success)),
    );
  }
}
