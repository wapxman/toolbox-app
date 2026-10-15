import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../home/main_screen.dart';

/// Открытие ячейки после оплаты аренды из бокса.
///
/// Экран не изображает успех: он сам даёт серверу команду «открыть» и
/// показывает ровно то, что ответил замок. Раньше здесь стоял таймер на три
/// секунды, и «Ячейка открыта!» рисовалась, даже когда бокс молчал (F18).
class UnlockScreen extends StatefulWidget {
  final String orderId;
  final String toolName;

  const UnlockScreen({super.key, required this.orderId, required this.toolName});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _api = ApiService();
  bool _opening = true;
  String? _error;
  dynamic _cellNumber;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() { _opening = true; _error = null; });
    try {
      final r = await _api.openCell(widget.orderId);
      if (!mounted) return;
      setState(() { _opening = false; _cellNumber = r['cell_number']; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _opening = false; _error = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _opening = false; _error = 'Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.'; });
    }
  }

  void _toOrders() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _opening ? _buildOpening() : (_error != null ? _buildFailed() : _buildOpened()),
          ),
        ),
      ),
    );
  }

  Widget _buildOpening() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
        ),
        const SizedBox(height: 28),
        const Text('Открываем ячейку...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Подождите, идёт связь с боксом',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  /// Замок подтвердил открытие — только теперь можно говорить «открыта».
  Widget _buildOpened() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          child: const Icon(Icons.lock_open, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 28),
        Text('Ячейка ${_cellNumber ?? ''} открыта!'.replaceAll('  ', ' '),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Заберите ${widget.toolName} и закройте дверцу',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _toOrders, child: const Text('Готово')),
      ],
    );
  }

  /// Замок НЕ открылся. Честно говорим и даём повторить — молча изображать
  /// успех нельзя: человек стоит перед закрытой дверцей.
  Widget _buildFailed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: AppTheme.error, size: 40),
        ),
        const SizedBox(height: 28),
        const Text('Ячейка не открылась',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.45)),
        const SizedBox(height: 10),
        Text('Оплата прошла, ${widget.toolName} закреплён за Вами — он не пропадёт.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _open, child: const Text('Попробовать ещё раз')),
        const SizedBox(height: 8),
        TextButton(onPressed: _toOrders, child: const Text('К заказам')),
      ],
    );
  }
}
