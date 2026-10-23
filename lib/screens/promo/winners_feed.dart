// Лента «Кто что выиграл» над профилем.
//
// Чужие живые выигрыши — лучший довод, что колесо настоящее, а не рекламная
// картинка. Номера приходят с сервера уже замаскированными: показываем ровно
// то, что он отдал, и ничего не достраиваем.
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import 'coin.dart';
import 'wheel_screen.dart';

/// Загружает ленту и показывает её. Не загрузилась или пуста — места не занимает:
/// это витрина, а не то, ради чего человек открыл профиль.
class WinnersFeed extends StatefulWidget {
  const WinnersFeed({super.key});

  @override
  State<WinnersFeed> createState() => _WinnersFeedState();
}

class _WinnersFeedState extends State<WinnersFeed> {
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ApiService().getWinners();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Сеть подвела — профиль важнее ленты, просто не показываем её.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return WinnersCard(
      items: _items,
      onOpenWheel: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WheelScreen())),
    );
  }
}

class WinnersCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback? onOpenWheel;

  const WinnersCard({super.key, required this.items, this.onOpenWheel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Кто что выиграл',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          if (onOpenWheel != null)
            InkWell(
              onTap: onOpenWheel,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Колесо Фортуны ›',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        for (final w in items.take(5)) _row(w),
      ]),
    );
  }

  Widget _row(Map<String, dynamic> w) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        w['kind'] == 'item'
            ? const Icon(Icons.handyman_outlined, size: 22, color: AppTheme.primary)
            : const TaketoolCoin(size: 22, shadow: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text(w['who']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Text(w['prize']?.toString() ?? '',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(_ago(w['at']),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ),
      ]),
    );
  }

  static String _ago(dynamic iso) {
    final t = DateTime.tryParse(iso?.toString() ?? '');
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'сейчас';
    if (d.inMinutes < 60) return '${d.inMinutes} мин';
    if (d.inHours < 24) return '${d.inHours} ч';
    if (d.inDays == 1) return 'вчера';
    return '${d.inDays} дн.';
  }
}
