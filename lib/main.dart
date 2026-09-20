import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'core/constants.dart';
import 'screens/welcome_screen.dart';
import 'screens/home/main_screen.dart';

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
  // Решение владельца (21.09.2026): регистрация по номеру телефона — на старте,
  // до каталога. Без входа приложение показывает только приветствие/вход.
  // AppFlags.requireLoginAtStart = false вернёт гостевой каталог (Apple 5.1.1(v)).
  final loggedIn = ApiService().isLoggedIn;
  runApp(TaketoolApp(showIntro: AppFlags.requireLoginAtStart ? !loggedIn : false));
}

class TaketoolApp extends StatelessWidget {
  final bool showIntro;
  const TaketoolApp({super.key, this.showIntro = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taketool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showIntro ? const WelcomeScreen() : const MainScreen(),
    );
  }
}
