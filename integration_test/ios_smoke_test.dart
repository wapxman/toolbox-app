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
    await tester.pumpWidget(const TaketoolApp(loggedIn: false));
    await shot(tester, '01_welcome');

    await tester.tap(find.text('Начать'));
    await settle(tester);
    await shot(tester, '02_onboarding_1');
    await tester.tap(find.text('Далее'));
    await settle(tester);
    await tester.tap(find.text('Далее'));
    await settle(tester);
    await shot(tester, '03_onboarding_3');
    await tester.tap(find.text('Начать'));
    await settle(tester);
    await shot(tester, '04_after_onboarding');

    // Входим демо-аккаунтом ревьюера — тем же, что указан в App Review
    // Information. Без токена «Профиль» и «Аренды» показывают ошибку загрузки,
    // и такие кадры в App Store отправлять нельзя.
    await ApiService().verify('+998900000001', '1234');

    // Главный экран с темой приложения и без отладочной ленты — иначе кадры
    // уходят в App Store с плашкой DEBUG и чужим оформлением.
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    ));
    await settle(tester, 6000);
    await shot(tester, '05_map');

    // Каталог бокса — четыре инструмента с ценами за день. Раньше здесь
    // снимался поиск, но он отдаёт максимум одну позицию, и кадр выходил
    // пустым. Карточка бокса показывает весь ассортимент.
    await tester.tap(find.text('Mega Planet ТЦ'));
    await settle(tester, 4000);
    await shot(tester, '06_box');

    // Карточка инструмента с ценой и бронированием.
    await tester.tap(find.textContaining('Перфоратор'));
    await settle(tester, 4000);
    await shot(tester, '07_tool');

    // Возвращаемся к главному экрану: инструмент -> бокс -> карта.
    await tester.pageBack();
    await settle(tester, 1500);
    await tester.pageBack();
    await settle(tester, 1500);

    await tester.tap(find.text('Профиль'));
    await settle(tester, 2500);
    await shot(tester, '08_profile');
    // Сканер открываем, чтобы экран был проверен, но снимок для App Store
    // здесь не делаем: в симуляторе нет камеры, и вместо видоискателя
    // выводится «Нет доступа к камере». Такой кадр можно снять только
    // на живом устройстве.
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await settle(tester, 3000);
  });
}
