import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

/// Реальный экран деталей аренды: живые данные из /rentals/active,
/// рабочий возврат (открывает замок через бэкенд) и продление.
/// Просрочка определяется по дате, а не только по статусу — бэкенд
/// может ещё не успеть проставить overdue кроном.
class RentalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rental;
  const RentalDetailScreen({super.key, required this.rental});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final _api = ApiService();
  bool _busy = false;

  Map<String, dynamic> get r => widget.rental;
  Map<String, dynamic> get tool => (r['tools'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get cell => (tool['cells'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get box => (cell['boxes'] as Map<String, dynamic>?) ?? {};

  DateTime? get _end => DateTime.tryParse(r['expected_end'] ?? '');
  bool get isOverdue =>
      r['status'] == 'overdue' ||
      (_end != null && DateTime.now().toUtc().isAfter(_end!.toUtc()));

  int get daysOver {
    if (!isOverdue || _end == null) return 0;
    final over = DateTime.now().toUtc().difference(_end!.toUtc()).inHours / 24.0;
    return over.ceil().clamp(1, 3650);
  }

  // Предварительная оценка штрафа (точный посчитает бэкенд при возврате)
  int get feeEstimate {
    final days = (r['days'] ?? 1) as int;
    final total = (r['total_price'] ?? 0) as int;
    if (days <= 0) return 0;
    return (daysOver * (total / days) * 1.5).round();
  }

  String _fmtDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final name = tool['name'] ?? 'Инструмент';
    final days = (r['days'] ?? 0) as int;

    return Scaffold(
      appBar: AppBar(title: const Text('Аренда')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка инструмента
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(Icons.build, color: AppTheme.textHint, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          '${box['name'] ?? 'Бокс'} • ячейка ${cell['cell_number'] ?? '—'}',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0xFFFDE8E8)
                        : const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(isOverdue ? 'Просрочена' : 'Активна',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? AppTheme.error
                              : const Color(0xFF1A6FB5))),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Плашка просрочки
            if (isOverdue) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Просрочка: $daysOver ${AppConstants.daysWord(daysOver)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error)),
                    const SizedBox(height: 4),
                    Text(
                        'Штраф при возврате: примерно ${AppConstants.formatPrice(feeEstimate)}. '
                        'Верните инструмент как можно скорее — штраф растёт каждый день.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.error,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Детали
            const Text('Детали',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _row('Срок', '$days ${AppConstants.daysWord(days)}'),
            _row('Начало', _fmtDate(r['started_at'])),
            _row('Возврат до', _fmtDate(r['expected_end'])),
            _row('Стоимость', AppConstants.formatPrice(r['total_price'] ?? 0)),
            _row('Бокс', '${box['name'] ?? '—'}'),
            if ((box['address'] ?? '') != '') _row('Адрес', '${box['address']}'),
            const SizedBox(height: 24),

            // Вернуть
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _confirmReturn,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Вернуть инструмент'),
              ),
            ),
            const SizedBox(height: 10),

            // Продлить
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _showExtend,
                child: const Text('Продлить аренду'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  // === Возврат ===

  Future<void> _confirmReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Вернуть инструмент?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(
          'Подойдите к боксу «${box['name'] ?? ''}». После подтверждения замок '
          'ячейки ${cell['cell_number'] ?? ''} откроется — положите инструмент '
          'и плотно закройте дверцу.'
          '${isOverdue ? '\n\nБудет начислен штраф за просрочку.' : ''}',
          style: TextStyle(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Открыть замок')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final res = await _api.returnRental(r['id']);
      if (!mounted) return;
      final fee = (res['overdue_fee'] ?? 0) as int;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(fee > 0 ? 'Возврат со штрафом' : 'Замок открыт',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Text(
            fee > 0
                ? 'Инструмент принят. Штраф за просрочку: ${AppConstants.formatPrice(fee)}. '
                    'Положите инструмент в ячейку и закройте дверцу.'
                : 'Положите инструмент в ячейку ${cell['cell_number'] ?? ''} и '
                    'плотно закройте дверцу. Спасибо!',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
          ),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true); // назад со сбросом списка
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Не удалось выполнить возврат. Проверьте интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // === Продление ===

  Future<void> _showExtend() async {
    int extraDays = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Продлить аренду',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed:
                    extraDays > 1 ? () => setD(() => extraDays--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('+$extraDays ${AppConstants.daysWord(extraDays)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed:
                    extraDays < 30 ? () => setD(() => extraDays++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Продлить')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final res = await _api.extendRental(r['id'], extraDays);
      if (!mounted) return;
      final extra = (res['extra_price'] ?? 0) as int;
      _toast('Продлено. Доплата: ${AppConstants.formatPrice(extra)}');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Не удалось продлить. Проверьте интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
