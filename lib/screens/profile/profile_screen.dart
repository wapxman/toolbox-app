import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../welcome_screen.dart';
import 'notifications_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 32, color: AppTheme.textHint),
            ),
            const SizedBox(height: 12),
            const Text('+998 90 123 45 67',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Пользователь',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 28),
            _menuItem(Icons.history, 'История аренд', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }),
            _menuItem(Icons.notifications_none, 'Уведомления', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            }),
            _menuItem(Icons.payment, 'Способы оплаты', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро!')),
              );
            }),
            _menuItem(Icons.help_outline, 'Помощь', () {
              _showHelp(context);
            }),
            _menuItem(Icons.info_outline, 'О приложении', () {
              _showAbout(context);
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
                child: const Text('Выйти'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Помощь', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(
          'По всем вопросам:\n\nТелефон: +998 71 200 00 00\nTelegram: @toolbox_support\n\nРежим работы: 24/7',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('О приложении', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ToolBox v1.0.0', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              'Аренда электроинструментов из умных боксов в Ташкенте. Быстро, удобно, 24/7.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
      ),
    );
  }
}
