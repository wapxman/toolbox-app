// Фирменный знак Taketool — контуром, а не буквой из шрифта.
//
// Знак только похож на «T»: перекладина обычная, а ножка смещена вправо и её
// верхний правый угол срезан по диагонали — получается силуэт молотка. Шрифтовая
// «Т» этого не передаёт, и рядом с настоящим логотипом разница бросается в глаза.
//
// Координаты сняты с assets/images/app_icon.png (1080×1080) и приведены к доле
// от стороны квадрата, поэтому знак одинаков в любом размере.
import 'package:flutter/material.dart';

/// Путь знака в квадрате [side] × [side], со смещением [offset].
Path taketoolMarkPath(double side, {Offset offset = Offset.zero}) {
  double x(double v) => offset.dx + v * side;
  double y(double v) => offset.dy + v * side;

  return Path()
    ..moveTo(x(0.2546), y(0.2519))   // левый верх перекладины
    ..lineTo(x(0.7444), y(0.2519))   // правый верх
    ..lineTo(x(0.7444), y(0.4204))   // правый низ перекладины
    ..lineTo(x(0.4972), y(0.4204))   // влево, до начала скоса
    ..lineTo(x(0.5880), y(0.4667))   // диагональный срез — тот самый «клык»
    ..lineTo(x(0.5880), y(0.7481))   // правый край ножки вниз
    ..lineTo(x(0.4167), y(0.7481))   // низ ножки
    ..lineTo(x(0.4167), y(0.4204))   // левый край ножки вверх
    ..lineTo(x(0.2546), y(0.4204))   // левый низ перекладины
    ..close();
}

/// Знак как виджет — для мест, где он нужен сам по себе.
class TaketoolMark extends StatelessWidget {
  final double size;
  final Color color;
  const TaketoolMark({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _MarkPainter(color)),
      );
}

class _MarkPainter extends CustomPainter {
  final Color color;
  _MarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(taketoolMarkPath(size.width), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.color != color;
}
