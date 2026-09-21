import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'unlock_screen.dart';
import 'order_placed_screen.dart';

/// Оплата заказа. Случаи:
///  - аренда/покупка из бокса   → после оплаты UnlockScreen (ячейка открыта)
///  - аренда/покупка с доставкой → после оплаты OrderPlacedScreen (ждём курьера)
///  - вызов курьера за инструментом (kind = courier_return, rentalId задан)
///  - оплата существующего счёта (existingOrderId: штраф за просрочку, повторная попытка)
/// Согласие с офертой: чекбокс снят по умолчанию, без него кнопка неактивна.
/// Факт согласия (кто, когда, редакция) бэкенд пишет в consents при создании заказа.
class PaymentScreen extends StatefulWidget {
  final String toolId;
  final String toolName;
  final String kind;          // rent | buy | courier_return | penalty
  final int days;
  final String fulfillment;   // pickup | delivery
  final Map<String, dynamic>? delivery;
  final String? slotLabel;
  final int itemsPrice;
  final int discount;
  final int deliveryFee;
  final int totalPrice;
  final String? rentalId;         // для courier_return — родительская аренда
  final String? existingOrderId;  // оплатить уже созданный заказ (штраф)

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
    this.existingOrderId,
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

  Map<String, dynamic>? _terms;     // действующая редакция оферты
  bool _termsAccepted = false;

  bool get isCourierReturn => widget.kind == 'courier_return';
  bool get isPenalty => widget.kind == 'penalty';
  bool get isDelivery => widget.fulfillment == 'delivery';
  bool get needsConsent => !isPenalty && widget.existingOrderId == null;

  @override
  void initState() {
    super.initState();
    _orderId = widget.existingOrderId;
    if (needsConsent) _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      final t = await _api.getTerms();
      if (mounted) setState(() => _terms = t);
    } catch (_) {
      // без версии оферты бэкенд заказ не примет — покажем ошибку при оплате
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
  }

  Future<Map<String, dynamic>> _create() {
    if (widget.existingOrderId != null) {
      return _api.payOrder(widget.existingOrderId!, provider: _selected);
    }
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
      termsVersion: _terms?['version']?.toString(),
    );
  }

  Future<void> _pay() async {
    if (_processing) return;
    if (needsConsent && !_termsAccepted) { _toast('Подтвердите согласие с офертой'); return; }
    if (needsConsent && _terms == null) {
      await _loadTerms();
      if (_terms == null) { _toast('Не удалось загрузить оферту. Проверьте интернет.'); return; }
    }
    setState(() => _processing = true);
    try {
      if (_orderId == null || widget.existingOrderId != null && _paymentUrl == null) {
        final res = await _create();
        _orderId = res['rental']?['id']?.toString() ?? _orderId;
        _paymentUrl = res['payment_url']?.toString();
        _clickInvoice = res['click_invoice'] == true;
      }
      if (_orderId == null) throw ApiException(0, 'Не удалось создать заказ');

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
        if (isPenalty || widget.existingOrderId != null) {
          Navigator.pop(context, true);
          return;
        }
        final Widget next = (isDelivery || isCourierReturn)
            ? OrderPlacedScreen(kind: widget.kind, toolName: widget.toolName,
                slotLabel: res['delivery_slot_label']?.toString() ?? widget.slotLabel)
            : UnlockScreen(toolName: widget.toolName, purchase: widget.kind == 'buy');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
        return;
      } else if (res['status'] == 'cancelled') {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() { _waitingPayment = false; _orderId = widget.existingOrderId; _paymentUrl = null; });
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
    if (isPenalty) return 'Штраф за просрочку аренды';
    if (isCourierReturn) return 'Вызов курьера за инструментом';
    final what = widget.kind == 'buy' ? 'Покупка нового' : 'Аренда ${widget.days} ${AppConstants.daysWord(widget.days)}';
    final how = isDelivery ? 'доставка' : 'из бокса';
    return '$what • $how';
  }

  bool get _canPay => !_processing && (!needsConsent || _termsAccepted);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isPenalty ? 'Оплата штрафа' : 'Оплата')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                if (!isCourierReturn && !isPenalty) _line(widget.kind == 'buy' ? 'Инструмент' : 'Аренда', AppConstants.formatPrice(widget.itemsPrice)),
                if (widget.discount > 0) _line('Скидка', '−${AppConstants.formatPrice(widget.discount)}', color: AppTheme.success),
                if (widget.deliveryFee > 0) _line(isCourierReturn ? 'Выезд курьера' : 'Доставка', AppConstants.formatPrice(widget.deliveryFee)),
                if (isPenalty) _line('Начатые дни сверх срока × цена дня × 1,5', ''),
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
            if (needsConsent) ...[
              const SizedBox(height: 20),
              _consentBox(),
            ],
            const SizedBox(height: 28),
            if (_waitingPayment && _timedOut) ...[
              Center(child: Column(children: [
                Icon(Icons.access_time, size: 40, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                const Text('Оплата пока не подтвердилась', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Если Вы уже оплатили — статус обновится сам, деньги не потеряются. Можно попробовать оплатить ещё раз или вернуться позже.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
            ] else if (_waitingPayment) ...[
              Center(child: Column(children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text('Ожидаем подтверждение оплаты...', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextButton(onPressed: _reopen, child: const Text('Открыть оплату ещё раз')),
              ])),
            ] else ...[
              ElevatedButton(
                onPressed: _canPay ? _pay : null,
                child: _processing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Оплатить ${AppConstants.formatPrice(widget.totalPrice)}'),
              ),
            ],
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _consentBox() {
    final date = (_terms?['date'] ?? '').toString();
    final url = (_terms?['url'] ?? LegalLinks.terms).toString();
    final link = TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: AppTheme.primary);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: _termsAccepted ? AppTheme.border : AppTheme.primary, width: _termsAccepted ? 1 : 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: _termsAccepted,
          activeColor: AppTheme.primary,
          onChanged: _waitingPayment ? null : (v) => setState(() => _termsAccepted = v ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                children: [
                  const TextSpan(text: 'Я прочитал(а) и принимаю '),
                  TextSpan(
                    text: 'Пользовательское соглашение (публичную оферту)',
                    style: link,
                    recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                  ),
                  TextSpan(text: date.isNotEmpty ? ' в редакции от $date' : ''),
                  const TextSpan(text: ', включая правила штрафа за просрочку, ответственность за утрату и условия доставки и продажи.'),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _reopen() async {
    if (_paymentUrl != null) await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.inAppBrowserView);
  }

  Widget _line(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(k, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textSecondary))),
          Text(v, style: TextStyle(fontSize: 13, color: color ?? AppTheme.textPrimary)),
        ]),
      );

  Widget _paymentOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: _waitingPayment ? null : () => setState(() { _selected = value; if (widget.existingOrderId != null) _paymentUrl = null; }),
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
