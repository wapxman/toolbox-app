import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
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
  // Вступление показываем только при самом первом запуске и только гостю.
  // Каталог обязан открываться без регистрации (App Store Guideline 5.1.1(v)).
  final prefs = await SharedPreferences.getInstance();
  final seenIntro = prefs.getBool('seen_intro') ?? false;
  runApp(TaketoolApp(showIntro: !ApiService().isLoggedIn && !seenIntro));
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
