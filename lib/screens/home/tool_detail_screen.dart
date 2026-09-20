import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import '../rental/order_screen.dart';
import '../auth/login_screen.dart';

/// Карточка инструмента. Здесь пользователь выбирает ЧТО: арендовать или купить.
/// КАК получить (из бокса / доставка) — на следующем экране оформления.
class ToolDetailScreen extends StatefulWidget {
  final String toolId;
  const ToolDetailScreen({super.key, required this.toolId});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _tool;
  int _deliveryFee = 50000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getTool(widget.toolId),
        _api.getDeliverySettings().catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _tool = results[0];
        _deliveryFee = (results[1]['fee'] ?? 50000) as int;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Оформление — действие уровня аккаунта: гостя просим войти только здесь
  /// (Guideline 5.1.1(v): просмотр каталога остаётся открытым).
  Future<void> _start(String kind) async {
    if (!_api.isLoggedIn) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(returnResult: true)),
      );
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrderScreen(tool: _tool!, kind: kind, deliveryFee: _deliveryFee),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_tool == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Инструмент не найден')));

    final tool = _tool!;
    final name = tool['name'] ?? '';
    final brand = tool['brand'] ?? '';
    final category = tool['category'] ?? '';
    final dayPrice = (tool['day_price'] ?? 0) as int;
    final salePrice = tool['sale_price'] as int?;
    final specs = tool['specs'] as Map<String, dynamic>? ?? {};
    final available = (tool['cell_status'] ?? tool['status'] ?? 'free') == 'free';
    final busyUntil = DateTime.tryParse(tool['busy_until']?.toString() ?? '')?.toLocal();
    final boxName = tool['box']?['name'] ?? tool['box_name'] ?? '';
    final boxAddress = tool['box']?['address'] ?? tool['box_address'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Инструмент')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ToolPhoto(url: tool['photo_url']?.toString(), width: double.infinity, height: 200, radius: 12, iconSize: 64),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text('$brand • $category', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: available ? const Color(0xFFE6F7EE) : const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                available
                    ? 'Свободен'
                    : (busyUntil != null
                        ? 'Занят до ${busyUntil.day.toString().padLeft(2, '0')}.${busyUntil.month.toString().padLeft(2, '0')}'
                        : 'Занят'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: available ? AppTheme.success : AppTheme.error),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Аренда
          _block(
            title: 'Аренда',
            icon: Icons.schedule,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${AppConstants.formatPrice(dayPrice)} / день',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text('от 1 до 30 дней', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('от 3 дней −20%', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                Text('от 7 дней −35%', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // Покупка
          if (salePrice != null)
            _block(
              title: 'Покупка',
              icon: Icons.shopping_bag_outlined,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppConstants.formatPrice(salePrice),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 6),
                _kv('Состояние', tool['sale_condition']?.toString() ?? 'Хорошее, б/у из проката'),
                if ((tool['sale_kit'] ?? '').toString().isNotEmpty) _kv('Комплект', tool['sale_kit'].toString()),
                if ((tool['sale_warranty'] ?? '').toString().isNotEmpty) _kv('Гарантия', tool['sale_warranty'].toString()),
              ]),
            ),
          const SizedBox(height: 10),

          // Получение
          _block(
            title: 'Как получить',
            icon: Icons.local_shipping_outlined,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _kv('Из бокса', 'бесплатно • $boxName${boxAddress.toString().isNotEmpty ? ', $boxAddress' : ''}'),
              _kv('Доставка по Ташкенту', '${AppConstants.formatPrice(_deliveryFee)} • сегодня или завтра'),
            ]),
          ),

          if (specs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Характеристики', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...specs.entries.map((e) => _kv(e.key, e.value.toString())),
          ],
          const SizedBox(height: 8),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: available
              ? Row(children: [
                  Expanded(
                    flex: salePrice != null ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () => _start('rent'),
                      child: const Text('Арендовать'),
                    ),
                  ),
                  if (salePrice != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _start('buy'),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Купить за ${AppConstants.formatPrice(salePrice)}'),
                        ),
                      ),
                    ),
                  ],
                ])
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text('Сейчас занят — загляните позже',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ),
        ),
      ),
    );
  }

  Widget _block({required String title, required IconData icon, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(k, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.35))),
        ]),
      );
}
