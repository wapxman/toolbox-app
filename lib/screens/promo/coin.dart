// Фирменная монета Taketool.
//
// Одна и та же монета летит в кошелёк после выигрыша, лежит на полосе бонуса
// и на карте счёта — поэтому она живёт здесь, а не рисуется трижды по-разному.
//
// Почему не просто жёлтый кружок: монета должна читаться как ценность. Этим
// занимаются четыре вещи, которых у кружка нет:
//   • гурт с насечками — то, по чему монета узнаётся даже в 16 пикселей;
//   • рант (бортик) — даёт толщину, иначе монета выглядит наклейкой;
//   • тиснение знака — утопленная тень снизу и светлый след сверху;
//   • косой блик — он и делает металл металлом, а не краской.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mark.dart';

class TaketoolCoin extends StatelessWidget {
  final double size;

  /// Тень под монетой. На светлом фоне нужна, внутри плотных карточек мешает.
  final bool shadow;

  const TaketoolCoin({super.key, this.size = 26, this.shadow = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        // Монета — готовая картинка: объёмное золото рисуется убедительнее,
        // чем всё, что можно начертить кодом. Знак на ней наш, наложен по
        // контуру из app_icon.png, а не шрифтовой буквой.
        //
        // Если файл почему-то не прочитается, падаем на рисованную монету —
        // пустое место вместо денег выглядело бы поломкой.
        child: Image.asset(
          'assets/images/coin.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              CustomPaint(size: Size(size, size), painter: _CoinPainter(shadow: shadow)),
        ),
      );
}

class _CoinPainter extends CustomPainter {
  final bool shadow;
  _CoinPainter({required this.shadow});

  // Золото: от почти белого блика до тёмной бронзы в тени.
  static const _light = Color(0xFFFFF6D0);
  static const _gold = Color(0xFFFFD75E);
  static const _deep = Color(0xFFE8A517);
  static const _edge = Color(0xFFA86F08);
  static const _brand = Color(0xFFDC0000);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    if (shadow) {
      canvas.drawCircle(
        c.translate(0, r * 0.08),
        r * 0.97,
        Paint()
          ..color = const Color(0x33A86F08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
      );
    }

    // Всё дальнейшее режем по кругу монеты: насечки рисуются толстой линией с
    // круглым концом и без обрезки торчат за край зубцами.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Тело монеты. Свет падает сверху-слева, поэтому центр градиента смещён
    // туда же — иначе диск выглядит плоским.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.45),
          radius: 1.05,
          colors: [_light, _gold, _deep, _edge],
          stops: [0.0, 0.42, 0.82, 1.0],
        ).createShader(rect),
    );

    // Гурт: насечки по ребру. Светлая и тёмная через одну — так ребро читается
    // объёмным. Их число растёт с размером: на мелкой монете частые риски
    // сливаются в грязь.
    final notches = size.width < 22 ? 18 : (size.width < 40 ? 26 : 36);
    final step = 2 * math.pi / notches;
    for (var i = 0; i < notches; i++) {
      final a = i * step;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 0.87);
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.02);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = i.isEven ? const Color(0x4DFFFFFF) : const Color(0x3A7A4F05)
          ..strokeWidth = math.max(0.5, r * 0.055)
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Рант — бортик между гуртом и полем. Он и даёт ощущение толщины.
    canvas.drawCircle(
      c,
      r * 0.84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.09)
        ..color = const Color(0x668A5A06),
    );

    // Поле монеты — чуть светлее тела, чтобы знак на нём не терялся.
    canvas.drawCircle(
      c,
      r * 0.78,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [_light, _gold, _deep],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.78)),
    );

    // Фирменный знак с тиснением: тёмный след снизу (утоплено) и светлый
    // сверху. Рисуем контуром, а не буквой из шрифта: у знака ножка смещена
    // вправо и срезана по диагонали, шрифтовая «Т» этого не передаёт.
    final markSide = r * 1.34;
    final markTopLeft = c - Offset(markSide / 2, markSide / 2);
    void letter(Color color, Offset shift) {
      canvas.drawPath(
        taketoolMarkPath(markSide, offset: markTopLeft + shift),
        Paint()..color = color,
      );
    }

    // Смещение тиснения намеренно маленькое: больше — и знак начинает двоиться,
    // особенно на крупной монете.
    final d = math.max(0.4, r * 0.022);
    letter(const Color(0x3A7A4F05), Offset(d, d));      // утопленная тень
    letter(const Color(0x4DFFFFFF), Offset(-d, -d));    // светлый след
    letter(_brand, Offset.zero);                        // сам знак

    // Косой блик — главное, что превращает жёлтый круг в металл.
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCenter(
          center: c.translate(-r * 0.3, -r * 0.46),
          width: r * 0.95,
          height: r * 0.5,
        )),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x70FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1),
    );

    canvas.restore(); // снимаем обрезку по кругу монеты

    // Тонкий тёмный контур по самому краю — отделяет монету от светлого фона.
    canvas.drawCircle(
      c,
      r - math.max(0.3, r * 0.025),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.05)
        ..color = const Color(0x99A86F08),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter old) => old.shadow != shadow;
}
