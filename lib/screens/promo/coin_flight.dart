// Монетки летят в кошелёк.
//
// Зачем вообще анимация, а не просто новая цифра в балансе: полёт связывает
// причину и следствие — «я выиграл» и «деньги теперь здесь». Молча
// увеличенный счётчик этой связи не даёт, человек его попросту не замечает.
//
// Как сделано (по разбору валютных анимаций в играх):
//  • монеты летят ПО ДУГЕ, а не по прямой — прямая линия выглядит дёшево;
//  • разлетаются из точки старта веером и собираются у цели, а не идут строем;
//  • у каждой свой сдвиг по времени, поэтому поток выглядит живым;
//  • перед самым кошельком — короткая пауза-акцент, затем иконка «клюёт»;
//  • счётчик баланса докручивается В МОМЕНТ прилёта, а не заранее.
//
// ⚠️ Уважаем системное «Убрать анимацию»: там, где человек просил покоя,
// монеты не летят — просто срабатывает колбэк прилёта.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Когда первая монета достигает кошелька. Совпадает с её путём в анимации:
/// старт почти сразу, полёт примерно половину общей длительности.
const int _firstArrivalMs = 580;

class CoinFlight {
  /// Запустить полёт монет из [from] в [to] (координаты экрана).
  ///
  /// [onArrive] зовётся, когда первая монета долетела — туда вешают докрутку
  /// счётчика. [onDone] — когда всё закончилось.
  static Future<void> play(
    BuildContext context, {
    required Offset from,
    required Offset to,
    int coins = 14,
    VoidCallback? onArrive,
    VoidCallback? onDone,
  }) async {
    // Человек попросил систему не анимировать — не спорим с ним.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      onArrive?.call();
      onDone?.call();
      return;
    }

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _CoinLayer(from: from, to: to, coins: coins),
    );
    overlay.insert(entry);

    // Момент прилёта первой монеты задаём явным сроком, а не слушателем
    // контроллера внутри слоя: слушатель живёт в оверлее, и до экрана его
    // колбэк не доходил — счётчик оставался нулём, пока монеты летели.
    // Срок совпадает с путём первой монеты (_firstArrivalMs).
    if (onArrive != null) {
      Future<void>.delayed(const Duration(milliseconds: _firstArrivalMs), onArrive);
    }

    // Общая длительность: пролёт последней монеты плюс её собственный путь.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    entry.remove();
    onDone?.call();
  }
}

class _CoinLayer extends StatefulWidget {
  final Offset from;
  final Offset to;
  final int coins;
  const _CoinLayer({required this.from, required this.to, required this.coins});

  @override
  State<_CoinLayer> createState() => _CoinLayerState();
}

class _CoinLayerState extends State<_CoinLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Coin> _coins;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _coins = List.generate(widget.coins, (i) {
      // Сдвиг по времени: поток, а не залп. 28 мс — на глаз читается как
      // «сыплются», но хвост не растягивается до скуки.
      final delay = i * 0.055 + rnd.nextDouble() * 0.02;
      // Разлёт из точки старта: веером в стороны и немного вверх.
      final spread = (rnd.nextDouble() - 0.5) * 180;
      final lift = 40 + rnd.nextDouble() * 90;
      return _Coin(
        delay: delay.clamp(0.0, 0.45),
        span: 0.5 + rnd.nextDouble() * 0.12,
        spread: spread,
        lift: lift,
        size: 15 + rnd.nextDouble() * 9,
        spin: (rnd.nextDouble() - 0.5) * 5,
        // Рассыпаются вокруг цели, а не втыкаются в одну точку.
        jitter: Offset((rnd.nextDouble() - 0.5) * 16, (rnd.nextDouble() - 0.5) * 16),
      );
    });

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1050))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          children: [
            for (final c in _coins) ..._paint(c),
          ],
        ),
      ),
    );
  }

  List<Widget> _paint(_Coin c) {
    final raw = (_ctrl.value - c.delay) / c.span;
    if (raw <= 0 || raw > 1.25) return const [];

    // Пауза-акцент: у цели монета на миг замирает, прежде чем впитаться.
    final t = raw.clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);

    final from = widget.from;
    final to = widget.to + c.jitter;

    // Дуга: контрольная точка сбоку и выше прямой, поэтому путь выгибается.
    final ctrl = Offset(
      (from.dx + to.dx) / 2 + c.spread,
      math.min(from.dy, to.dy) - c.lift,
    );
    final p = _quad(from, ctrl, to, eased);

    // Появляется быстро, у цели гаснет — чтобы исчезновение не было резким.
    final opacity = t < 0.1 ? t / 0.1 : (t > 0.88 ? (1 - t) / 0.12 : 1.0);
    final scale = t > 0.9 ? 1 - (t - 0.9) * 2.2 : 1.0;

    return [
      Positioned(
        left: p.dx - c.size / 2,
        top: p.dy - c.size / 2,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: t * c.spin,
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.0),
              child: _coinDot(c.size),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _coinDot(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD75E), Color(0xFFE8A517)],
          ),
          border: Border.all(color: const Color(0xFFB87C09), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFFE8A517).withOpacity(.45), blurRadius: 6),
          ],
        ),
        child: Center(
          child: Text(
            'T',
            style: TextStyle(
              fontSize: size * 0.58,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
        ),
      );

  /// Квадратичная кривая Безье — та самая дуга.
  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }
}

class _Coin {
  final double delay;   // когда вылетает (доля общей длительности)
  final double span;    // сколько летит
  final double spread;  // вбок от прямой — задаёт изгиб дуги
  final double lift;    // насколько дуга поднимается
  final double size;
  final double spin;
  final Offset jitter;  // разброс у цели
  const _Coin({
    required this.delay, required this.span, required this.spread,
    required this.lift, required this.size, required this.spin, required this.jitter,
  });
}

/// Счётчик, который докручивается до новой суммы. Ставится там, где виден
/// баланс: цифра должна ожить в момент прилёта монет, а не прыгнуть заранее.
class AnimatedAmount extends StatelessWidget {
  final int from;
  final int to;
  final TextStyle? style;
  final String Function(int) format;
  final Duration duration;

  const AnimatedAmount({
    super.key,
    required this.from,
    required this.to,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: to.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v.round()), style: style),
    );
  }
}
