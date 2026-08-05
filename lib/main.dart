import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  runApp(TaketoolApp(loggedIn: ApiService().isLoggedIn));
}

class TaketoolApp extends StatelessWidget {
  final bool loggedIn;
  const TaketoolApp({super.key, this.loggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taketool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: loggedIn ? const MainScreen() : const WelcomeScreen(),
    );
  }
}
