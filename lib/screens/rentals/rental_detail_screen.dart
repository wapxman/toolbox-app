import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/order_labels.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import '../rental/courier_return_screen.dart';

/// Детали заказа: аренда/покупка, из бокса/с доставкой.
/// - доставка: таймлайн, адрес, курьер, отмена до передачи курьеру
/// - активная аренда: возврат (в бокс или курьером), продление, просрочка
class RentalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rental;
  const RentalDetailScreen({super.key, required this.rental});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final _api = ApiService();
  late Map<String, dynamic> r = widget.rental;
  bool _busy = false;
  bool _changed = false;

  Map<String, dynamic> get tool => (r['tools'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get cell => (tool['cells'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get box => (cell['boxes'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic>? get courierReturn => r['courier_return'] as Map<String, dynamic>?;

  String get kind => r['kind'] ?? 'rent';
  bool get isRent => kind == 'rent';
  bool get isDelivery => r['fulfillment'] == 'delivery';
  String get status => r['status'] ?? 'active';
  bool get isRentActive => isRent && (status == 'active' || status == 'overdue');
  bool get isOverdue => OrderLabels.isOverdue(r);

  DateTime? get _end => DateTime.tryParse(r['expected_end'] ?? '')?.toLocal();
  int get daysOver {
    if (!isOverdue || _end == null) return 0;
    return (DateTime.now().difference(_end!).inHours / 24.0).ceil().clamp(1, 3650);
  }
  int get feeEstimate {
    final days = (r['days'] ?? 1) as int;
    final total = ((r['items_price'] ?? r['total_price'] ?? 0) as int) - ((r['discount'] ?? 0) as int);
    if (days <= 0) return 0;
    return (daysOver * (total / days) * 1.5).round();
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _api.getRental(r['id'].toString());
      if (mounted) setState(() => r = fresh);
    } catch (_) {}
  }

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final name = tool['name'] ?? 'Инструмент';
    final st = OrderLabels.status(r);
    final number = r['order_number'];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) Navigator.pop(context, _changed); },
      child: Scaffold(
        appBar: AppBar(title: Text(number != null ? 'Заказ № $number' : (isRent ? 'Аренда' : 'Покупка'))),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Карточка
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    ToolPhoto(url: tool['photo_url']?.toString(), width: 56, height: 56, radius: 8, iconSize: 26),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 3),
                      Text(OrderLabels.kindLine(r, cellNumber: cell['cell_number']),
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(999)),
                    child: Text(st.text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: st.fg)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              if (isDelivery && status == 'pending_delivery') ...[_timeline(), const SizedBox(height: 16)],

              if (isDelivery) ...[_deliveryInfo(), const SizedBox(height: 16)],

              if (courierReturn != null) ...[_courierReturnCard(), const SizedBox(height: 16)],

              if (isRentActive && isOverdue) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Просрочка: $daysOver ${AppConstants.daysWord(daysOver)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.error)),
                    const SizedBox(height: 4),
                    Text('Штраф при возврате: примерно ${AppConstants.formatPrice(feeEstimate)}. '
                        'Верните инструмент как можно скорее — штраф растёт каждый день.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.error, height: 1.4)),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              const Text('Детали', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (isRent) _row('Срок', '${r['days']} ${AppConstants.daysWord((r['days'] ?? 0) as int)}'),
              if (isRent && (status == 'active' || status == 'overdue' || status == 'completed')) ...[
                _row('Начало', _fmtDate(r['started_at'])),
                _row(status == 'completed' ? 'Возвращён' : 'Вернуть до', _fmtDate(status == 'completed' ? r['actual_end'] : r['expected_end'])),
              ],
              if ((r['discount'] ?? 0) > 0) _row('Скидка', '−${AppConstants.formatPrice(r['discount'] as int)}'),
              if ((r['delivery_fee'] ?? 0) > 0) _row('Доставка', AppConstants.formatPrice(r['delivery_fee'] as int)),
              _row('Оплачено', AppConstants.formatPrice((r['total_price'] ?? 0) as int)),
              if ((r['overdue_fee'] ?? 0) > 0) _row('Штраф', AppConstants.formatPrice(r['overdue_fee'] as int)),
              if (!isDelivery) _row('Бокс', '${box['name'] ?? '—'}'),
              if (!isDelivery && (box['address'] ?? '') != '') _row('Адрес бокса', '${box['address']}'),
              const SizedBox(height: 24),

              ..._actions(),
            ]),
          ),
        ),
      ),
    );
  }

  // === Блоки ===

  Widget _timeline() {
    final ds = r['delivery_status'] ?? 'paid';
    final isReturn = kind == 'courier_return';
    final steps = [
      ('paid', 'Оплачен', _fmtDate(r['paid_at'])),
      ('packed', 'Собран', r['packed_at'] != null ? _fmtDate(r['packed_at']) : 'Готовим к отправке'),
      ('dispatched', 'Курьер в пути', r['dispatched_at'] != null ? _fmtDate(r['dispatched_at']) : (r['delivery_slot_label'] ?? '')),
      ('delivered', isReturn ? 'Забран' : 'Доставлен', isRent ? 'Отсюда начнётся срок аренды' : ''),
    ];
    final order = ['paid', 'packed', 'dispatched', 'delivered'];
    final cur = order.indexOf(ds);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        for (var i = 0; i < steps.length; i++)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < cur ? AppTheme.success : (i == cur ? AppTheme.primary : Colors.white),
                  border: Border.all(color: i <= cur ? Colors.transparent : AppTheme.border, width: 2),
                ),
                child: i < cur ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (i < steps.length - 1)
                Container(width: 2, height: 26, color: i < cur ? AppTheme.success : AppTheme.border),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(steps[i].$2, style: TextStyle(
                  fontSize: 14, fontWeight: i == cur ? FontWeight.w700 : FontWeight.w500,
                  color: i > cur ? AppTheme.textSecondary : AppTheme.textPrimary)),
                if (steps[i].$3.isNotEmpty)
                  Text(steps[i].$3, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            )),
          ]),
      ]),
    );
  }

  Widget _deliveryInfo() {
    final parts = [r['delivery_address']];
    if ((r['delivery_entrance'] ?? '').toString().isNotEmpty) parts.add('подъезд ${r['delivery_entrance']}');
    if ((r['delivery_floor'] ?? '').toString().isNotEmpty) parts.add('этаж ${r['delivery_floor']}');
    if ((r['delivery_apt'] ?? '').toString().isNotEmpty) parts.add('кв. ${r['delivery_apt']}');
    final courier = (r['courier_name'] ?? '').toString();
    final courierPhone = (r['courier_phone'] ?? '').toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Доставка', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(parts.where((p) => p != null && p.toString().isNotEmpty).join(', '),
            style: const TextStyle(fontSize: 13.5, height: 1.35)),
        if ((r['delivery_slot_label'] ?? '').toString().isNotEmpty)
          Text(r['delivery_slot_label'], style: const TextStyle(fontSize: 13.5, height: 1.35)),
        if ((r['recipient_phone'] ?? '').toString().isNotEmpty)
          Text('Получатель: ${r['recipient_phone']}', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        if (courier.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('Курьер $courier${courierPhone.isNotEmpty ? ' · $courierPhone' : ''}',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
          ]),
        ],
      ]),
    );
  }

  Widget _courierReturnCard() {
    final cr = courierReturn!;
    final ds = cr['delivery_status'];
    final text = cr['status'] == 'pending_payment'
        ? 'Вызов курьера не оплачен'
        : ds == 'dispatched'
            ? 'Курьер едет за инструментом${(cr['courier_name'] ?? '') != '' ? ': ${cr['courier_name']} ${cr['courier_phone'] ?? ''}' : ''}'
            : 'Курьер вызван: ${cr['delivery_slot_label'] ?? ''}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A6FB5))),
        const SizedBox(height: 4),
        Text('Аренда завершится, когда курьер заберёт инструмент.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
        if (ds != 'dispatched') ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _cancel(cr['id'].toString(), 'Отменить вызов курьера?'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            child: const Text('Отменить вызов курьера'),
          ),
        ],
      ]),
    );
  }

  List<Widget> _actions() {
    final w = <Widget>[];
    Widget btn(Widget child, VoidCallback? onTap, {bool outlined = false}) => SizedBox(
          width: double.infinity,
          child: outlined ? OutlinedButton(onPressed: onTap, child: child) : ElevatedButton(onPressed: onTap, child: child),
        );
    final spinner = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

    if (status == 'pending_delivery') {
      final ds = r['delivery_status'];
      if (ds == 'paid' || ds == 'packed') {
        w.add(btn(const Text('Отменить заказ'), _busy ? null : () => _cancel(r['id'].toString(),
            'Отменить заказ? Деньги вернутся тем же способом оплаты в течение 1–3 дней.'), outlined: true));
      } else {
        w.add(Text('Курьер уже в пути — отмена недоступна. Вопросы: ${LegalLinks.supportPhone}',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)));
      }
      return w;
    }

    if (isRentActive) {
      if (courierReturn == null) {
        w.add(btn(_busy ? spinner : const Text('Вернуть инструмент'), _busy ? null : _chooseReturn));
        w.add(const SizedBox(height: 10));
      }
      w.add(btn(const Text('Продлить аренду'), _busy ? null : _showExtend, outlined: true));
    }
    return w;
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  // === Действия ===

  Future<void> _cancel(String id, String question) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Отмена', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(question, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да, отменить')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final res = await _api.cancelOrder(id);
      _changed = true;
      _toast(res['message']?.toString() ?? 'Отменено');
      await _refresh();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Не удалось отменить. Проверьте интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseReturn() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Как вернуть?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _returnOption(
              icon: Icons.inventory_2_outlined,
              title: 'Сдать в бокс',
              subtitle: '${box['name'] ?? 'Бокс'}${(box['address'] ?? '') != '' ? ', ${box['address']}' : ''}. Ячейка ${cell['cell_number'] ?? ''} откроется — положите инструмент.',
              price: 'бесплатно', priceColor: AppTheme.success,
              onTap: () => Navigator.pop(context, 'box'),
            ),
            const SizedBox(height: 10),
            _returnOption(
              icon: Icons.local_shipping_outlined,
              title: 'Вызвать курьера',
              subtitle: 'Заберём по вашему адресу в выбранное время',
              price: 'платно', priceColor: AppTheme.textPrimary,
              onTap: () => Navigator.pop(context, 'courier'),
            ),
          ]),
        ),
      ),
    );
    if (choice == 'box') await _returnToBox();
    if (choice == 'courier' && mounted) {
      final paid = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (_) => CourierReturnScreen(rentalId: r['id'].toString(), toolName: tool['name'] ?? 'инструмент'),
      ));
      if (paid == true) _changed = true;
      await _refresh();
    }
  }

  Widget _returnOption({required IconData icon, required String title, required String subtitle,
      required String price, required Color priceColor, required VoidCallback onTap}) =>
      InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.35)),
            ])),
            const SizedBox(width: 8),
            Text(price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: priceColor)),
          ]),
        ),
      );

  Future<void> _returnToBox() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Вернуть инструмент?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(
          'Подойдите к боксу «${box['name'] ?? ''}». После подтверждения замок ячейки ${cell['cell_number'] ?? ''} '
          'откроется — положите инструмент и плотно закройте дверцу.'
          '${isOverdue ? '\n\nБудет начислен штраф за просрочку.' : ''}',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Открыть замок')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final res = await _api.returnRental(r['id'].toString());
      if (!mounted) return;
      final fee = (res['overdue_fee'] ?? 0) as int;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(fee > 0 ? 'Возврат со штрафом' : 'Замок открыт', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Text(
            fee > 0
                ? 'Инструмент принят. Штраф за просрочку: ${AppConstants.formatPrice(fee)}. Положите инструмент в ячейку и закройте дверцу.'
                : 'Положите инструмент в ячейку ${cell['cell_number'] ?? ''} и плотно закройте дверцу. Спасибо!',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
          ),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Готово'))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Не удалось выполнить возврат. Проверьте интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showExtend() async {
    int extraDays = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Продлить аренду', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: extraDays > 1 ? () => setD(() => extraDays--) : null, icon: const Icon(Icons.remove_circle_outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('+$extraDays ${AppConstants.daysWord(extraDays)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            IconButton(onPressed: extraDays < 30 ? () => setD(() => extraDays++) : null, icon: const Icon(Icons.add_circle_outline)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Продлить')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final res = await _api.extendRental(r['id'].toString(), extraDays);
      if (!mounted) return;
      final extra = (res['extra_price'] ?? 0) as int;
      _toast('Продлено. Доплата: ${AppConstants.formatPrice(extra)}');
      _changed = true;
      await _refresh();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Не удалось продлить. Проверьте интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
