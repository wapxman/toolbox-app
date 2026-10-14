// Вход в акцию: карточка в ленте и всплывающее приглашение.
//
// Почему именно так, а не попапом на старте: модалка до того, как человек
// успел что-то получить от приложения, — известный антипаттерн. Она закрывает
// содержимое, читается как «тут всё платно» и бьёт по доверию. Поэтому:
//
//   • КАРТОЧКА в ленте — постоянная, её нельзя «проиграть», она не мешает;
//   • МОДАЛКА — только после осмысленного действия (посмотрел инструменты),
//     не чаще раза за запуск, с жёстким потолком показов.
//
// Карточка нарочно свёрстана как элемент интерфейса, а не как рекламный
// баннер: всё, что выглядит рекламой, взгляд пропускает мимо.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'wheel_screen.dart';

/// Правила показа приглашения.
///
/// Состояние держим на телефоне. Для частоты показа этого достаточно: цена
/// ошибки — лишняя модалка, а не лишние деньги. Сам приз защищён на сервере,
/// там переустановка ничего не даёт.
class WheelPromo {
  static const _kShown = 'wheel_promo_shown';     // сколько раз показали
  static const _kLast = 'wheel_promo_last';       // когда показали в последний раз
  static const _kMuted = 'wheel_promo_muted';     // человек закрыл дважды — молчим
  static const _kSpun = 'wheel_promo_spun';       // уже крутил — звать больше незачем

  static const _maxShows = 3;        // всего, за всё время
  static const _repeatDays = 3;      // не чаще раза в трое суток
  static const _actionsBefore = 2;   // сколько осмысленных действий ждём

  static bool _shownThisRun = false; // один раз за запуск
  static int _actions = 0;

  /// Отметить осмысленное действие: открыл карточку инструмента, бокс, магазин.
  static void noteAction() => _actions++;

  /// Пометить, что человек уже крутил — приглашать больше не нужно.
  static Future<void> markSpun() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSpun, true);
  }

  static Future<bool> _shouldShow() async {
    if (_shownThisRun || _actions < _actionsBefore) return false;
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kSpun) == true || p.getBool(_kMuted) == true) return false;
    if ((p.getInt(_kShown) ?? 0) >= _maxShows) return false;

    final last = p.getInt(_kLast) ?? 0;
    if (last > 0) {
      final days = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(last))
          .inDays;
      if (days < _repeatDays) return false;
    }
    return true;
  }

  /// Показать приглашение, если по правилам пора. Зовётся с главных экранов.
  static Future<void> maybeShow(BuildContext context) async {
    if (!await _shouldShow()) return;
    if (!context.mounted) return;

    _shownThisRun = true;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kShown, (p.getInt(_kShown) ?? 0) + 1);
    await p.setInt(_kLast, DateTime.now().millisecondsSinceEpoch);

    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => const _WheelInvite(),
    );

    if (go == true && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelScreen()));
    } else {
      // Второй отказ подряд — человек ясно дал понять. Больше не зовём.
      final refusals = (p.getInt('wheel_promo_refused') ?? 0) + 1;
      await p.setInt('wheel_promo_refused', refusals);
      if (refusals >= 2) await p.setBool(_kMuted, true);
    }
  }
}

/// Приглашение покрутить. Закрывается и крестиком, и тапом мимо — модалка,
/// которую нельзя закрыть, раздражает сильнее всего.
class _WheelInvite extends StatelessWidget {
  const _WheelInvite();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: AppTheme.textHint,
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          const _WheelMark(size: 86),
          const SizedBox(height: 14),
          const Text('Колесо Фортуны',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Одна попытка — бонус на аренду инструмента. '
            'Главные призы: шуруповёрт, перфоратор и 1 000 000 сум.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Крутить',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Не сейчас',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ]),
      ),
    );
  }
}

/// Карточка акции. Постоянная точка входа — то, чего гостю не хватало:
/// колесо жило в профиле, а профиль у гостя закрыт.
///
/// [floating] — для главной: там карточка лежит поверх карты, поэтому ей нужна
/// тень вместо рамки, иначе она тонет в картинке. В ленте магазина наоборот:
/// тень выглядела бы рекламной наклейкой, а всё похожее на рекламу взгляд
/// пропускает мимо.
class WheelBanner extends StatelessWidget {
  final bool floating;
  const WheelBanner({super.key, this.floating = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: floating
          ? const EdgeInsets.fromLTRB(16, 0, 16, 0)
          : const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        elevation: floating ? 3 : 0,
        shadowColor: Colors.black.withOpacity(.22),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WheelScreen())),
          child: Container(
            padding: EdgeInsets.all(floating ? 11 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: floating ? null : Border.all(color: AppTheme.borderLight),
            ),
            child: Row(children: [
              _WheelMark(size: floating ? 38 : 46),
              SizedBox(width: floating ? 11 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Колесо Фортуны',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      'Одна попытка — бонус на аренду',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const Text('Крутить',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Значок колеса — тот же мотив, что и на самом экране, чтобы карточка,
/// приглашение и экран читались как одно целое.
class _WheelMark extends StatelessWidget {
  final double size;
  const _WheelMark({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    const n = 8;
    const colors = [Color(0xFFDC0000), Color(0xFF0D0D0D), Colors.white];
    final sweep = 2 * 3.1415926535 / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -3.1415926535 / 2 - sweep / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
    }
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(c, r * 0.3, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.3, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..color = const Color(0xFF0D0D0D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
