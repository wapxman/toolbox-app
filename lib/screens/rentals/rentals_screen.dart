import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import '../../core/order_labels.dart';
import 'rental_detail_screen.dart';

/// Вкладка «Заказы»: аренды, покупки и доставки. Активные / История.
class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  final _api = ApiService();
  List<dynamic> _active = [];
  List<dynamic> _history = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.getActiveRentals(), _api.getRentalHistory()]);
      if (mounted) setState(() { _active = results[0]; _history = results[1]; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _active : _history;
    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [_seg(0, 'Активные'), _seg(1, 'История')]),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text(_tab == 0 ? 'Нет активных заказов' : 'История пуста',
                          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Загляните в Магазин — аренда или покупка, из бокса или с доставкой',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _card(list[i] as Map<String, dynamic>),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _seg(int i, String label) {
    final active = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 3, offset: const Offset(0, 1))] : null,
          ),
          child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary)),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final tool = r['tools'] as Map<String, dynamic>? ?? {};
    final name = tool['name'] ?? 'Инструмент';
    final st = OrderLabels.status(r);
    final cell = tool['cells'] as Map<String, dynamic>? ?? {};

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => RentalDetailScreen(rental: r)),
        );
        if (changed == true) _load();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: st.danger ? AppTheme.error.withOpacity(0.35) : AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ToolPhoto(url: tool['photo_url']?.toString(), width: 52, height: 52, radius: 8, iconSize: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
              const SizedBox(height: 3),
              Text(OrderLabels.kindLine(r, cellNumber: cell['cell_number']),
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(st.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: st.fg)),
              ),
            ),
            const SizedBox(width: 10),
            Text(AppConstants.formatPrice((r['total_price'] ?? 0) as int),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}
