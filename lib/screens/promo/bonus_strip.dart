// Бонусный счёт на виду.
//
// Выигранный бонус бесполезен, если человек о нём не помнит. Поэтому счёт
// показывается там, где принимаются решения, а не только в профиле, куда
// заходят редко. Здесь — две формы одного и того же:
//
//   • BonusStrip — полоса на главной: сколько есть и когда сгорит;
//   • BonusPriceChip — скидка прямо на цене товара в списке.
//
// Срок сгорания указан намеренно: именно он возвращает человека в приложение.
// Умолчать о нём — значит дать бонусу тихо сгореть.
import 'package:flutter/material.dart';
import '../../core/bonus_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'wallet_screen.dart';

/// Золотая монетка — тот же знак, что летит в кошелёк после выигрыша.
class BonusCoin extends StatelessWidget {
  final double size;
  const BonusCoin({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD75E), Color(0xFFE8A517)],
          ),
          border: Border.all(color: const Color(0xFFB87C09)),
        ),
        child: Center(
          child: Text('T',
              style: TextStyle(
                fontSize: size * 0.56,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              )),
        ),
      );
}

/// Полоса «у вас есть бонус» для главной. Сама прячется, когда бонуса нет.
class BonusStrip extends StatefulWidget {
  const BonusStrip({super.key});

  @override
  State<BonusStrip> createState() => _BonusStripState();
}

class _BonusStripState extends State<BonusStrip> {
  final _bonus = BonusService();

  @override
  void initState() {
    super.initState();
    _bonus.addListener(_onChange);
    _bonus.refresh();
  }

  @override
  void dispose() {
    _bonus.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    if (!_bonus.hasBonus) return const SizedBox.shrink();
    final days = _bonus.daysLeft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Material(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: const Color(0xFFF0DFAE)),
            ),
            child: Row(children: [
              const BonusCoin(size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppConstants.formatPrice(_bonus.balance)} на аренду',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6A4E00)),
                    ),
                    if (days != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        days <= 0
                            ? 'сгорает сегодня'
                            : days == 1
                                ? 'сгорит завтра'
                                : 'сгорит через $days ${AppConstants.daysWord(days)}',
                        style: TextStyle(
                          fontSize: 11,
                          // Последняя неделя — красным: это уже срочно.
                          color: days <= 7 ? AppTheme.primary : const Color(0xFF8A7330),
                          fontWeight: days <= 7 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Text('Потратить',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Карта бонусного счёта для профиля. Тёмная с золотым — чтобы читалась как
/// ценность, а не как очередная строка меню.
class BonusCard extends StatefulWidget {
  const BonusCard({super.key});

  @override
  State<BonusCard> createState() => _BonusCardState();
}

class _BonusCardState extends State<BonusCard> {
  final _bonus = BonusService();

  @override
  void initState() {
    super.initState();
    _bonus.addListener(_onChange);
    _bonus.refresh();
  }

  @override
  void dispose() {
    _bonus.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    if (!_bonus.hasBonus) return const SizedBox.shrink();
    final days = _bonus.daysLeft;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF3A2E12), Color(0xFF6B4F10)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const BonusCoin(size: 22),
          const SizedBox(width: 8),
          Text('Бонусный счёт',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(.82))),
        ]),
        const SizedBox(height: 6),
        Text(
          AppConstants.formatPrice(_bonus.balance),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          days == null
              ? 'покрывает до ${_bonus.maxPayPct}% стоимости аренды'
              : days <= 0
                  ? 'сгорает сегодня · до ${_bonus.maxPayPct}% аренды'
                  : 'сгорит через $days ${AppConstants.daysWord(days)} · до ${_bonus.maxPayPct}% аренды',
          style: TextStyle(
            fontSize: 11,
            color: (days != null && days <= 7)
                ? const Color(0xFFFFC9C9)
                : Colors.white.withOpacity(.75),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: const Text('Куда потратить',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

/// Скидка на цене товара: «бонусом −38 400». Показывает конечную цену, а не
/// абстрактный остаток на счету — так бонус превращается из цифры в выгоду.
class BonusPriceChip extends StatelessWidget {
  /// Цена позиции, от которой считается потолок (за весь срок или за штуку).
  final int itemsPrice;
  const BonusPriceChip({super.key, required this.itemsPrice});

  @override
  Widget build(BuildContext context) {
    final cut = BonusService().applicableTo(itemsPrice);
    if (cut <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        'бонусом −${AppConstants.formatPrice(cut)}',
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1C9A4B)),
      ),
    );
  }
}
