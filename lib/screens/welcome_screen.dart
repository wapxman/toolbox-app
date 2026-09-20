import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';

/// Первый экран: приветствие → «Начать» (онбординг → регистрация по телефону)
/// или «Войти». Каталог открывается только после входа.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              Image.asset('assets/images/logo.png', height: 64, fit: BoxFit.contain),
              const SizedBox(height: 18),
              Text(
                'Аренда и продажа электроинструментов.\nИз умных боксов или с доставкой по Ташкенту',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
                child: const Text('Начать'),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(text: 'Уже есть аккаунт? ', style: TextStyle(color: AppTheme.textSecondary)),
                      TextSpan(text: 'Войти', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
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
