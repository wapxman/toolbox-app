import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../welcome_screen.dart';

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
            // Avatar
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
            const Text(
              '+998 90 123 45 67',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Пользователь',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            // Menu items
            _menuItem(Icons.history, 'История аренд', () {}),
            _menuItem(Icons.notifications_none, 'Уведомления', () {}),
            _menuItem(Icons.payment, 'Способы оплаты', () {}),
            _menuItem(Icons.help_outline, 'Помощь', () {}),
            _menuItem(Icons.info_outline, 'О приложении', () {}),
            const SizedBox(height: 20),
            // Logout
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
