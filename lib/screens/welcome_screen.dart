import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_prefs.dart';
import 'onboarding_screen.dart';
import 'home/main_screen.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Открыть каталог без регистрации (Guideline 5.1.1(v)).
  static Future<void> _openCatalog(BuildContext context) async {
    await AppPrefs.markIntroSeen();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Логотип Taketool
              Image.asset(
                'assets/images/logo.png',
                height: 64,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text(
                'Аренда электроинструментов\nиз умных боксов. Быстро, удобно, 24/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 2),
              // CTA buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  );
                },
                child: const Text('Начать'),
              ),
              const SizedBox(height: 12),
              // Гостевой вход: каталог доступен без регистрации
              TextButton(
                onPressed: () => _openCatalog(context),
                child: Text(
                  'Смотреть каталог без регистрации',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, fontFamily: 'SFPro'),
                    children: [
                      TextSpan(
                        text: 'Уже есть аккаунт? ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextSpan(
                        text: 'Войти',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
