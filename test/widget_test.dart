import 'package:flutter_test/flutter_test.dart';

import 'package:toolbox_app/core/constants.dart';

void main() {
  group('priceForDays — цена от конкретного инструмента', () {
    test('1 день без скидки', () {
      expect(AppConstants.priceForDays(1, 50000), 50000);
    });

    test('3 дня со скидкой 20%', () {
      expect(AppConstants.priceForDays(3, 50000), 120000);
    });

    test('7 дней со скидкой 35%', () {
      expect(AppConstants.priceForDays(7, 60000), 273000);
    });

    test('разные инструменты — разные итоги (регресс бага «всегда 80 000»)', () {
      expect(AppConstants.priceForDays(1, 50000),
          isNot(AppConstants.priceForDays(1, 90000)));
    });
  });

  test('formatPrice разделяет тысячи', () {
    expect(AppConstants.formatPrice(120000), '120 000 сўм');
  });
}
