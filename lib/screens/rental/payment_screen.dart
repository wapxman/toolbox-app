import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'unlock_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String toolId;
  final String toolName;
  final int days;
  final int totalPrice;

  const PaymentScreen({
    super.key,
    required this.toolId,
    required this.toolName,
    required this.days,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _api = ApiService();
  String _selected = 'payme';
  bool _processing = false;      // создаём аренду / открываем оплату
  bool _waitingPayment = false;  // ссылка открыта, ждём callback от Payme
  bool _timedOut = false;        // подтверждение не пришло за отведённое время
  int _pollTicks = 0;            // сколько раз опросили статус
  static const int _maxPollTicks = 40; // 40 × 3с = 2 минуты ожидания
  String? _rentalId;
  String? _paymentUrl;
  bool _clickInvoice = false;   // Click метод 3: счёт отправлен в приложение Click Up
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pay() async {
    if (_processing) return;

    setState(() => _processing = true);
    try {
      // 1) Создаём аренду (pending_payment), если ещё не создана.
      //    provider выбирает способ оплаты: payme или click.
      if (_rentalId == null) {
        final res = await _api.createRental(widget.toolId, widget.days, provider: _selected);
        _rentalId = res['rental']?['id']?.toString();
        _paymentUrl = res['payment_url']?.toString();
        _clickInvoice = res['click_invoice'] == true;
      }

      if (_rentalId == null) {
        throw ApiException(0, 'Не удалось создать аренду');
      }

      // Click метод 3: счёт с суммой уже отправлен пушем в приложение Click Up.
      // Ссылку НЕ открываем — пользователь подтверждает оплату в Click, а мы ждём
      // подтверждение через опрос статуса (SHOP API Complete активирует аренду).
      if (_selected == 'click' && _clickInvoice) {
        _toast('Счёт отправлен в приложение Click. Подтвердите оплату.');
        // Как в Payme — сразу открываем приложение Click, где уже ждёт счёт с суммой.
        if (_paymentUrl != null && _paymentUrl!.isNotEmpty && _paymentUrl != 'null') {
          try {
            await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
        setState(() { _processing = false; _waitingPayment = true; _timedOut = false; _pollTicks = 0; });
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaid());
        return;
      }

      if (_paymentUrl == null || _paymentUrl!.isEmpty || _paymentUrl == 'null') {
        throw ApiException(0, 'Оплата временно недоступна, попробуйте позже');
      }

      // 2) Открываем страницу оплаты во ВСТРОЕННОМ вью.
      //    Через externalApplication Android отдавал ссылку установленному
      //    приложению (Payme/Click Up), и оно checkout-ссылку не открывало.
      //    Click: ссылку my.click.uz жёстко перехватывает Click Up (verified
      //    app links срабатывают даже в Custom Tab), поэтому Click открываем во
      //    встроенном WebView — он рендерит страницу внутри приложения и НЕ
      //    отдаёт ссылку внешнему приложению. Payme оставляем в Custom Tab.
      final uri = Uri.parse(_paymentUrl!);
      final primaryMode = _selected == 'click'
          ? LaunchMode.inAppWebView
          : LaunchMode.inAppBrowserView;
      bool opened = false;
      try {
        opened = await launchUrl(uri, mode: primaryMode);
      } catch (_) {}
      if (!opened) {
        try {
          opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }
      if (!opened) {
        try {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
      if (!opened) throw ApiException(0, 'Не удалось открыть страницу оплаты');

      // 3) Ждём подтверждение оплаты (webhook Payme -> наш бэкенд)
      setState(() { _processing = false; _waitingPayment = true; _timedOut = false; _pollTicks = 0; });
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaid());
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _toast(e is ApiException ? e.message : 'Ошибка оплаты');
    }
  }

  Future<void> _checkPaid() async {
    if (_rentalId == null) return;
    _pollTicks++;
    try {
      final res = await _api.getPaymentStatus(_rentalId!);
      if (res['paid'] == true) {
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UnlockScreen(toolName: widget.toolName)),
        );
        return;
      } else if (res['status'] == 'cancelled') {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() { _waitingPayment = false; _rentalId = null; _paymentUrl = null; });
        _toast('Оплата отменена');
        return;
      }
    } catch (_) {
      // сеть мигнула — попробуем в следующем тике
    }
    // Подтверждение не пришло за отведённое время — не висим вечно
    if (_pollTicks >= _maxPollTicks) {
      _pollTimer?.cancel();
      if (!mounted) return;
      setState(() => _timedOut = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
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
                  Text(
                    widget.toolName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.days} ${AppConstants.daysWord(widget.days)}',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'К оплате',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Text(
                        AppConstants.formatPrice(widget.totalPrice),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment method
            const Text(
              'Способ оплаты',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _paymentOption(
              'payme',
              'Payme',
              Icons.account_balance_wallet,
              const Color(0xFF33CCCC),
            ),
            const SizedBox(height: 10),
            _paymentOption(
              'click',
              'Click',
              Icons.touch_app,
              const Color(0xFF00AAFF),
            ),
            const Spacer(),

            if (_waitingPayment && _timedOut) ...[
              // Подтверждение не пришло за 2 минуты — не держим бесконечный спиннер
              Center(
                child: Column(
                  children: [
                    Icon(Icons.access_time, size: 40, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'Оплата пока не подтвердилась',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
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
                        _pollTimer = Timer.periodic(
                            const Duration(seconds: 3), (_) => _checkPaid());
                      },
                      child: const Text('Проверить ещё раз'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        if (_paymentUrl != null) {
                          await launchUrl(Uri.parse(_paymentUrl!),
                              mode: LaunchMode.inAppBrowserView);
                        }
                      },
                      child: const Text('Открыть оплату ещё раз'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_waitingPayment) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Ожидаем подтверждение оплаты...',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        if (_paymentUrl != null) {
                          await launchUrl(Uri.parse(_paymentUrl!),
                              mode: LaunchMode.inAppBrowserView);
                        }
                      },
                      child: const Text('Открыть оплату ещё раз'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              ElevatedButton(
                onPressed: _processing ? null : _pay,
                child: _processing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Оплатить ${AppConstants.formatPrice(widget.totalPrice)}',
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _paymentOption(
      String value, String label, IconData icon, Color color) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
