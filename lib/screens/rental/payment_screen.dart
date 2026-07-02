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
  String? _rentalId;
  String? _paymentUrl;
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

    if (_selected == 'click') {
      _toast('Click скоро подключим — пока доступен Payme');
      return;
    }

    setState(() => _processing = true);
    try {
      // 1) Создаём аренду (pending_payment), если ещё не создана
      if (_rentalId == null) {
        final res = await _api.createRental(widget.toolId, widget.days);
        _rentalId = res['rental']?['id']?.toString();
        _paymentUrl = res['payment_url']?.toString();
      }

      if (_rentalId == null) {
        throw ApiException(0, 'Не удалось создать аренду');
      }
      if (_paymentUrl == null || _paymentUrl!.isEmpty || _paymentUrl == 'null') {
        throw ApiException(0, 'Оплата временно недоступна, попробуйте позже');
      }

      // 2) Открываем страницу оплаты Payme
      final opened = await launchUrl(
        Uri.parse(_paymentUrl!),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw ApiException(0, 'Не удалось открыть страницу оплаты');

      // 3) Ждём подтверждение оплаты (webhook Payme -> наш бэкенд)
      setState(() { _processing = false; _waitingPayment = true; });
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
    try {
      final res = await _api.getPaymentStatus(_rentalId!);
      if (res['paid'] == true) {
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UnlockScreen(toolName: widget.toolName)),
        );
      } else if (res['status'] == 'cancelled') {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() { _waitingPayment = false; _rentalId = null; _paymentUrl = null; });
        _toast('Оплата отменена');
      }
    } catch (_) {
      // сеть мигнула — попробуем в следующем тике
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
      ),
      body: Padding(
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

            if (_waitingPayment) ...[
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
                              mode: LaunchMode.externalApplication);
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
