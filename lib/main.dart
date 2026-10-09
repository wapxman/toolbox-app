import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'core/constants.dart';
import 'core/push_service.dart';
import 'core/deep_link_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home/main_screen.dart';

/// Нужен, чтобы открыть экран бокса по ссылке из QR: событие приходит
/// извне дерева виджетов, обычного context там нет.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Восстанавливаем сохранённый вход, чтобы не логиниться каждый раз через SMS
  await ApiService().loadToken();
  // Пуши. init() никогда не бросает: если Firebase недоступен, приложение
  // просто работает без уведомлений. Токен отдаём только залогиненным —
  // ручка регистрации устройства под авторизацией.
  await PushService().init();
  PushService().registerIfLoggedIn();
  // 08.10.2026 владелец отменил требование входа на старте (стояло с 21.09.2026):
  // каталог открыт гостям на ОБЕИХ платформах, номер просим при оформлении аренды.
  // Цифры воронки, из-за которых решение изменили, — в комментарии к
  // AppFlags.requireLoginAtStart.
  final loggedIn = ApiService().isLoggedIn;
  runApp(TaketoolApp(showIntro: AppFlags.requireLoginAtStart ? !loggedIn : false));
  // После runApp: навигатор к этому моменту уже существует, и ссылка,
  // которой приложение запустили, откроет нужный бокс.
  DeepLinkService().init(navigatorKey);
}

class TaketoolApp extends StatelessWidget {
  final bool showIntro;
  const TaketoolApp({super.key, this.showIntro = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taketool',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showIntro ? const WelcomeScreen() : const MainScreen(),
    );
  }
}
