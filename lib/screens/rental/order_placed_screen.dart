import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../home/main_screen.dart';

/// Экран после оплаты заказа с доставкой / вызова курьера / покупки из бокса.
class OrderPlacedScreen extends StatelessWidget {
  final String kind; // rent | buy | courier_return | buy_pickup
  final String toolName;
  final String? slotLabel;

  const OrderPlacedScreen({super.key, required this.kind, required this.toolName, this.slotLabel});

  @override
  Widget build(BuildContext context) {
    final isReturn = kind == 'courier_return';
    // Покупка из бокса: заказ оплачен, но его ещё КЛАДУТ в ячейку. Обещать
    // открытую ячейку сейчас нельзя — она откроется после готовности (F18).
    final isPickupBuy = kind == 'buy_pickup';
    final title = isReturn ? 'Курьер вызван' : isPickupBuy ? 'Заказ оплачен' : 'Заказ оформлен';
    final text = isReturn
        ? 'Курьер заберёт $toolName${slotLabel != null ? ': $slotLabel' : ''}. Аренда завершится, когда инструмент окажется у курьера.'
        : isPickupBuy
            ? 'Мы кладём $toolName в ячейку. Как заказ будет готов — придёт уведомление, тогда подходите к боксу и забирайте.'
            : kind == 'buy'
                ? 'Курьер привезёт $toolName${slotLabel != null ? ': $slotLabel' : ''}. Перед выездом мы напишем в уведомлениях.'
                : 'Курьер привезёт $toolName${slotLabel != null ? ': $slotLabel' : ''}. Срок аренды начнётся, когда вы получите инструмент.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: Icon(
                    isReturn ? Icons.undo : isPickupBuy ? Icons.inventory_2_outlined : Icons.local_shipping_outlined,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 28),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(text, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.45)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
                  (_) => false,
                ),
                child: const Text('К заказам'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
