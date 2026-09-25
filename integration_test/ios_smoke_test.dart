import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:toolbox_app/main.dart';
import 'package:toolbox_app/core/theme.dart';
import 'package:toolbox_app/core/api_service.dart';
import 'package:toolbox_app/screens/home/main_screen.dart';

Future<void> settle(WidgetTester t, [int ms = 1500]) async {
  await t.pump(Duration(milliseconds: ms));
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t, 800);
    await binding.takeScreenshot(name);
  }

  testWidgets('walk through screens', (tester) async {
    // Снимаем гостевой путь: на iOS приложение открывается сразу каталогом,
    // приветствия и онбординга там нет (Guideline 5.1.1(v)). Кадры с ними
    // показывали бы экраны, до которых ревьюер физически не дойдёт.
    await tester.pumpWidget(const TaketoolApp());
    await settle(tester, 8000);
    await shot(tester, '01_map');

    // Магазин — главная новинка версии. Долгая пауза ради фотографий
    // инструментов: они тянутся с CloudFront, и при меньшем ожидании в кадр
    // попадают пустые плашки. Проверено на прошлом наборе: 8 секунд мало.
    await tester.tap(find.text('Магазин'));
    await settle(tester, 15000);
    await shot(tester, '02_shop');

    // Карточка инструмента: цена аренды, цена покупки, доставка.
    // Именно .first: «Перфоратор» встречается и в названии, и в строке
    // категории «Einhell • Перфораторы» — без уточнения два совпадения.
    await tester.tap(find.textContaining('Перфоратор').first);
    await settle(tester, 6000);
    await shot(tester, '03_tool');

    await tester.pageBack();
    await settle(tester, 2000);

    // Режим «Покупка» — продажа новых единиц со склада.
    await tester.tap(find.text('Покупка'));
    await settle(tester, 12000);
    await shot(tester, '04_buy');

    // Каталог бокса со свободными ячейками — через карту.
    await tester.tap(find.text('Главная'));
    await settle(tester, 3000);
    await tester.tap(find.text('Mega Planet ТЦ'));
    await settle(tester, 15000);
    await shot(tester, '05_box');

    // Профиль снимаем только после входа демо-аккаунтом ревьюера: у гостя
    // там приглашение войти, а такой кадр в App Store отправлять незачем.
    await ApiService().verify('+998900000001', '1234');
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    ));
    await settle(tester, 6000);
    await tester.tap(find.text('Профиль'));
    await settle(tester, 3000);
    await shot(tester, '06_profile');
  });
}
