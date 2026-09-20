import 'package:flutter/material.dart';
import 'constants.dart';
import 'theme.dart';

/// Человеческие подписи заказа: что это (аренда/покупка), как получаем, статус.
class OrderStatusLabel {
  final String text;
  final Color fg;
  final Color bg;
  final bool danger;
  const OrderStatusLabel(this.text, this.fg, this.bg, {this.danger = false});
}

class OrderLabels {
  static String _dm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  static DateTime? end(Map<String, dynamic> r) => DateTime.tryParse(r['expected_end']?.toString() ?? '')?.toLocal();

  static bool isOverdue(Map<String, dynamic> r) {
    if (r['status'] == 'overdue') return true;
    if (r['status'] != 'active') return false;
    final e = end(r);
    return e != null && DateTime.now().isAfter(e);
  }

  /// «Аренда 3 дня · Доставка» / «Покупка · Из бокса, ячейка 4»
  static String kindLine(Map<String, dynamic> r, {dynamic cellNumber}) {
    final kind = r['kind'] ?? 'rent';
    final days = (r['days'] ?? 0) as int;
    final what = kind == 'buy' ? 'Покупка' : 'Аренда $days ${AppConstants.daysWord(days)}';
    final delivery = r['fulfillment'] == 'delivery';
    final pickupCell = (r['pickup_cell'] as Map<String, dynamic>?)?['cell_number'];
    final cellNo = kind == 'buy' ? pickupCell : cellNumber;
    final how = delivery ? 'Доставка' : 'Из бокса${cellNo != null ? ', ячейка $cellNo' : ''}';
    return '$what · $how';
  }

  static OrderStatusLabel status(Map<String, dynamic> r) {
    const green = Color(0xFFE6F7EE), blue = Color(0xFFE8F4FD), amber = Color(0xFFFFF4E5), red = Color(0xFFFDE8E8), gray = Color(0xFFF0F0EE);
    const blueFg = Color(0xFF1A6FB5), amberFg = Color(0xFFB86400);
    final s = r['status'];
    final kind = r['kind'] ?? 'rent';
    final slot = r['delivery_slot_label']?.toString();
    if (s == 'cancelled') {
      final rf = r['refund_status'];
      final tail = rf == 'pending' ? ' · возврат денег в пути' : rf == 'done' ? ' · деньги возвращены' : '';
      return OrderStatusLabel('Отменён$tail', AppTheme.textSecondary, gray);
    }
    if (s == 'pending_payment') return OrderStatusLabel('Ждёт оплаты', amberFg, amber);
    if (s == 'pending_delivery') {
      final ds = r['delivery_status'];
      if (ds == 'ready') {
        final cellNo = (r['pickup_cell'] as Map<String, dynamic>?)?['cell_number'];
        return OrderStatusLabel('Готов к выдаче${cellNo != null ? ' · ячейка $cellNo' : ''}', blueFg, blue);
      }
      if (ds == 'dispatched') return OrderStatusLabel('Курьер в пути${slot != null ? ' · $slot' : ''}', blueFg, blue);
      if (ds == 'packed') return OrderStatusLabel('Собран${slot != null ? ' · $slot' : ''}', amberFg, amber);
      if (kind == 'buy' && r['fulfillment'] != 'delivery') return OrderStatusLabel('Оплачен, кладём в бокс', amberFg, amber);
      return OrderStatusLabel('Оплачен, готовим${slot != null ? ' · $slot' : ''}', amberFg, amber);
    }
    if (s == 'completed') {
      if (kind == 'buy') return OrderStatusLabel('Куплен', AppTheme.success, green);
      return OrderStatusLabel('Возвращён${(r['overdue_fee'] ?? 0) > 0 ? ' со штрафом' : ''}', AppTheme.success, green);
    }
    if (isOverdue(r)) return OrderStatusLabel('Просрочена', AppTheme.error, red, danger: true);
    final e = end(r);
    return OrderStatusLabel('Активна${e != null ? ' · вернуть до ${_dm(e)}' : ''}', AppTheme.success, green);
  }
}
