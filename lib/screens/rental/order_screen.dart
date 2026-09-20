import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import '../../widgets/delivery_form.dart';
import 'payment_screen.dart';

/// Оформление заказа. Заголовок «Аренда» или «Покупка» — чтобы всегда было ясно, что оформляем.
/// Порядок: (срок аренды) → как получить: из бокса / доставка → адрес и время → итог → к оплате.
class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> tool;
  final String kind; // rent | buy
  final int deliveryFee;

  const OrderScreen({super.key, required this.tool, required this.kind, required this.deliveryFee});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _api = ApiService();
  final _delivery = DeliveryFormController();
  int _days = 1;
  String _fulfillment = 'pickup';
  List<dynamic> _slots = [];
  bool _slotsLoading = true;

  bool get isRent => widget.kind == 'rent';
  int get dayPrice => (widget.tool['day_price'] ?? 0) as int;
  int get salePrice => (widget.tool['sale_price'] ?? 0) as int;
  int get itemsFull => isRent ? _days * dayPrice : salePrice;
  int get itemsPrice => isRent ? AppConstants.priceForDays(_days, dayPrice) : salePrice;
  int get discount => itemsFull - itemsPrice;
  int get deliveryFee => _fulfillment == 'delivery' ? widget.deliveryFee : 0;
  int get total => itemsPrice + deliveryFee;

  String get boxName => widget.tool['box']?['name'] ?? widget.tool['box_name'] ?? 'бокс';
  String get boxAddress => widget.tool['box']?['address'] ?? widget.tool['box_address'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _prefillPhone();
  }

  Future<void> _loadSlots() async {
    try {
      final s = await _api.getDeliverySettings();
      if (mounted) setState(() { _slots = s['slots'] ?? []; _slotsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  Future<void> _prefillPhone() async {
    try {
      final me = await _api.getMe();
      final phone = (me['user']?['phone'] ?? me['phone'] ?? '').toString();
      if (phone.isNotEmpty && _delivery.phone.text.isEmpty) _delivery.phone.text = phone;
    } catch (_) {}
  }

  @override
  void dispose() {
    _delivery.dispose();
    super.dispose();
  }

  void _setDays(int d) {
    if (d >= 1 && d <= 30) setState(() => _days = d);
  }

  void _goPay() {
    if (_fulfillment == 'delivery') {
      final err = _delivery.validate();
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentScreen(
        toolId: widget.tool['id'].toString(),
        toolName: widget.tool['name']?.toString() ?? '',
        kind: widget.kind,
        days: isRent ? _days : 0,
        fulfillment: _fulfillment,
        delivery: _fulfillment == 'delivery' ? _delivery.toJson() : null,
        slotLabel: _fulfillment == 'delivery' ? _delivery.slotLabel : null,
        itemsPrice: itemsFull,
        discount: discount,
        deliveryFee: deliveryFee,
        totalPrice: total,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRent ? 'Аренда' : 'Покупка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _toolCard(),
          const SizedBox(height: 22),
          if (isRent) ...[
            const Text('Срок аренды', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _daysPicker(),
            const SizedBox(height: 22),
          ],
          const Text('Как получить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _option(
            value: 'pickup',
            icon: Icons.inventory_2_outlined,
            title: 'Заберу из бокса',
            subtitle: '$boxName${boxAddress.isNotEmpty ? ', $boxAddress' : ''}\nЯчейка откроется сразу после оплаты',
            price: 'бесплатно',
            priceColor: AppTheme.success,
          ),
          const SizedBox(height: 10),
          _option(
            value: 'delivery',
            icon: Icons.local_shipping_outlined,
            title: 'Доставка курьером',
            subtitle: 'В любую точку Ташкента, сегодня или завтра',
            price: AppConstants.formatPrice(widget.deliveryFee),
            priceColor: AppTheme.textPrimary,
          ),
          if (_fulfillment == 'delivery') ...[
            const SizedBox(height: 18),
            const Text('Куда привезти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _slotsLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                : DeliveryForm(controller: _delivery, slots: _slots),
            if (isRent) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                child: Text('Срок аренды начнётся, когда курьер передаст инструмент, а не с момента оплаты.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4)),
              ),
            ],
          ],
          const SizedBox(height: 22),
          _summary(),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _goPay, child: const Text('К оплате')),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _toolCard() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(children: [
          ToolPhoto(url: widget.tool['photo_url']?.toString(), width: 52, height: 52, radius: 8, iconSize: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.tool['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              isRent ? '${AppConstants.formatPrice(dayPrice)} / день' : 'Покупка • ${AppConstants.formatPrice(salePrice)}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ])),
        ]),
      );

  Widget _daysPicker() => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _counterButton(Icons.remove, () => _setDays(_days - 1)),
          const SizedBox(width: 24),
          Column(children: [
            Text('$_days', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600)),
            Text(AppConstants.daysWord(_days), style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(width: 24),
          _counterButton(Icons.add, () => _setDays(_days + 1)),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 3, 5, 7, 14].map((d) {
            final active = _days == d;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _setDays(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text('$d ${AppConstants.daysWord(d)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: active ? Colors.white : AppTheme.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ]);

  Widget _counterButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.border)),
          child: Icon(icon, color: AppTheme.textSecondary, size: 24),
        ),
      );

  Widget _option({
    required String value, required IconData icon, required String title,
    required String subtitle, required String price, required Color priceColor,
  }) {
    final selected = _fulfillment == value;
    return GestureDetector(
      onTap: () => setState(() => _fulfillment = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 2 : 1),
          color: selected ? const Color(0xFFFFF8F8) : Colors.white,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.textHint, size: 22),
          const SizedBox(width: 10),
          Icon(icon, size: 22, color: AppTheme.textPrimary),
          const SizedBox(width: 10),
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
  }

  Widget _summary() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        child: Column(children: [
          _line(isRent ? '$_days ${AppConstants.daysWord(_days)} × ${AppConstants.formatPrice(dayPrice)}' : 'Инструмент',
              AppConstants.formatPrice(itemsFull)),
          if (discount > 0)
            _line('Скидка ${_days >= 7 ? '−35%' : '−20%'}', '−${AppConstants.formatPrice(discount)}', color: AppTheme.success),
          _line(_fulfillment == 'delivery' ? 'Доставка' : 'Из бокса',
              _fulfillment == 'delivery' ? AppConstants.formatPrice(deliveryFee) : 'бесплатно'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Итого', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(AppConstants.formatPrice(total),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ]),
        ]),
      );

  Widget _line(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textSecondary)),
          Text(v, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textSecondary, fontWeight: color != null ? FontWeight.w500 : null)),
        ]),
      );
}
