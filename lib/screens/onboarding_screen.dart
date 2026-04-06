import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      icon: Icons.map_outlined,
      title: 'Найдите ближайший бокс',
      description: 'Откройте карту и выберите бокс\nрядом с вами. Инструменты всегда под рукой.',
    ),
    _Slide(
      icon: Icons.qr_code_scanner,
      title: 'Сканируйте QR-код',
      description: 'Наведите камеру на QR-код бокса.\nОплатите и заберите инструмент.',
    ),
    _Slide(
      icon: Icons.handyman_outlined,
      title: 'Работайте и верните',
      description: 'Используйте инструмент сколько нужно.\nВерните в любой бокс ToolBox.',
    ),
  ];

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToRegister();
    }
  }

  void _goToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: 3,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            s.icon,
                            size: 64,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppTheme.primary : AppTheme.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Bottom nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _goToRegister,
                    child: Text(
                      'Пропустить',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: Text(_page == 2 ? 'Начать' : 'Далее'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String description;
  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
  });
}
