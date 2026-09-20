import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'unlock_screen.dart';
import 'order_placed_screen.dart';

/// Оплата заказа. Работает для трёх случаев:
///  - аренда/покупка из бокса   → после оплаты UnlockScreen (ячейка открыта)
///  - аренда/покупка с доставкой → после оплаты OrderPlacedScreen (ждём курьера)
///  - вызов курьера за инструментом (kind = courier_return, rentalId задан)
class PaymentScreen extends StatefulWidget {
  final String toolId;
  final String toolName;
  final String kind;          // rent | buy | courier_return
  final int days;
  final String fulfillment;   // pickup | delivery
  final Map<String, dynamic>? delivery;
  final String? slotLabel;
  final int itemsPrice;
  final int discount;
  final int deliveryFee;
  final int totalPrice;
  final String? rentalId;     // для courier_return — родительская аренда

  const PaymentScreen({
    super.key,
    required this.toolId,
    required this.toolName,
    this.kind = 'rent',
    this.days = 0,
    this.fulfillment = 'pickup',
    this.delivery,
    this.slotLabel,
    this.itemsPrice = 0,
    this.discount = 0,
    this.deliveryFee = 0,
    required this.totalPrice,
    this.rentalId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _api = ApiService();
  String _selected = 'payme';
  bool _processing = false;
  bool _waitingPayment = false;
  bool _timedOut = false;
  int _pollTicks = 0;
  static const int _maxPollTicks = 40; // 40 × 3с = 2 минуты
  String? _orderId;
  String? _paymentUrl;
  bool _clickInvoice = false;
  Timer? _pollTimer;

  bool get isCourierReturn => widget.kind == 'courier_return';
  bool get isDelivery => widget.fulfillment == 'delivery';

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Map<String, dynamic>> _create() {
    if (isCourierReturn) {
      return _api.returnByCourier(widget.rentalId!, provider: _selected, delivery: widget.delivery ?? {});
    }
    return _api.createOrder(
      toolId: widget.toolId,
      kind: widget.kind,
      days: widget.days,
      fulfillment: widget.fulfillment,
      provider: _selected,
      delivery: widget.delivery,
    );
  }

  Future<void> _pay() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (_orderId == null) {
        final res = await _create();
        _orderId = res['rental']?['id']?.toString();
        _paymentUrl = res['payment_url']?.toString();
        _clickInvoice = res['click_invoice'] == true;
      }
      if (_orderId == null) throw ApiException(0, 'Не удалось создать заказ');

      // Click метод 3: счёт уже в Click Up — открываем приложение Click и ждём подтверждение.
      if (_selected == 'click' && _clickInvoice) {
        _toast('Счёт отправлен в приложение Click. Подтвердите оплату.');
        if (_paymentUrl != null && _paymentUrl!.isNotEmpty && _paymentUrl != 'null') {
          try { await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.externalApplication); } catch (_) {}
        }
        _startPolling();
        return;
      }

      if (_paymentUrl == null || _paymentUrl!.isEmpty || _paymentUrl == 'null') {
        throw ApiException(0, 'Оплата временно недоступна, попробуйте позже');
      }

      // Payme — Custom Tab; Click — встроенный WebView (иначе ссылку перехватывает Click Up).
      final uri = Uri.parse(_paymentUrl!);
      final primaryMode = _selected == 'click' ? LaunchMode.inAppWebView : LaunchMode.inAppBrowserView;
      bool opened = false;
      try { opened = await launchUrl(uri, mode: primaryMode); } catch (_) {}
      if (!opened) { try { opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView); } catch (_) {} }
      if (!opened) { try { opened = await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {} }
      if (!opened) throw ApiException(0, 'Не удалось открыть страницу оплаты');

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _toast(e is ApiException ? e.message : 'Ошибка оплаты');
    }
  }

  void _startPolling() {
    setState(() { _processing = false; _waitingPayment = true; _timedOut = false; _pollTicks = 0; });
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaid());
  }

  Future<void> _checkPaid() async {
    if (_orderId == null) return;
    _pollTicks++;
    try {
      final res = await _api.getPaymentStatus(_orderId!);
      if (res['paid'] == true) {
        _pollTimer?.cancel();
        if (!mounted) return;
        final Widget next = (isDelivery || isCourierReturn)
            ? OrderPlacedScreen(kind: widget.kind, toolName: widget.toolName,
                slotLabel: res['delivery_slot_label']?.toString() ?? widget.slotLabel)
            : UnlockScreen(toolName: widget.toolName, purchase: widget.kind == 'buy');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
        return;
      } else if (res['status'] == 'cancelled') {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() { _waitingPayment = false; _orderId = null; _paymentUrl = null; });
        _toast('Оплата отменена');
        return;
      }
    } catch (_) {}
    if (_pollTicks >= _maxPollTicks) {
      _pollTimer?.cancel();
      if (!mounted) return;
      setState(() => _timedOut = true);
    }
  }

  String get _whatLabel {
    if (isCourierReturn) return 'Вызов курьера за инструментом';
    final what = widget.kind == 'buy' ? 'Покупка' : 'Аренда ${widget.days} ${AppConstants.daysWord(widget.days)}';
    final how = isDelivery ? 'доставка' : 'из бокса';
    return '$what • $how';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.toolName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_whatLabel, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                if (widget.slotLabel != null && widget.slotLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(widget.slotLabel!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 10),
                if (!isCourierReturn) _line(widget.kind == 'buy' ? 'Инструмент' : 'Аренда', AppConstants.formatPrice(widget.itemsPrice)),
                if (widget.discount > 0) _line('Скидка', '−${AppConstants.formatPrice(widget.discount)}', color: AppTheme.success),
                if (widget.deliveryFee > 0) _line(isCourierReturn ? 'Выезд курьера' : 'Доставка', AppConstants.formatPrice(widget.deliveryFee)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('К оплате', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(AppConstants.formatPrice(widget.totalPrice),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Способ оплаты', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _paymentOption('payme', 'Payme', Icons.account_balance_wallet, const Color(0xFF33CCCC)),
            const SizedBox(height: 10),
            _paymentOption('click', 'Click', Icons.touch_app, const Color(0xFF00AAFF)),
            const Spacer(),
            if (_waitingPayment && _timedOut) ...[
              Center(child: Column(children: [
                Icon(Icons.access_time, size: 40, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                const Text('Оплата пока не подтвердилась', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Если Вы уже оплатили — статус обновится сам, деньги не потеряются. '
                    'Можно попробовать оплатить ещё раз или вернуться позже.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() { _timedOut = false; _pollTicks = 0; });
                    _pollTimer?.cancel();
                    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaid());
                  },
                  child: const Text('Проверить ещё раз'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _reopen, child: const Text('Открыть оплату ещё раз')),
              ])),
              const SizedBox(height: 16),
            ] else if (_waitingPayment) ...[
              Center(child: Column(children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text('Ожидаем подтверждение оплаты...', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextButton(onPressed: _reopen, child: const Text('Открыть оплату ещё раз')),
              ])),
              const SizedBox(height: 16),
            ] else ...[
              ElevatedButton(
                onPressed: _processing ? null : _pay,
                child: _processing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Оплатить ${AppConstants.formatPrice(widget.totalPrice)}'),
              ),
              const SizedBox(height: 16),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _reopen() async {
    if (_paymentUrl != null) {
      await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.inAppBrowserView);
    }
  }

  Widget _line(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textSecondary)),
          Text(v, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textPrimary)),
        ]),
      );

  Widget _paymentOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: _waitingPayment ? null : () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight, width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
        ]),
      ),
    );
  }
}
