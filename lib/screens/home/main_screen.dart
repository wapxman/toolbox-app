import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import '../rentals/rentals_screen.dart';
import '../profile/profile_screen.dart';
import '../rental/qr_scanner_screen.dart';
import '../auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onQrTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  /// Гостю вместо личных разделов показываем приглашение войти,
  /// чтобы не дёргать защищённые эндпоинты без токена и не ловить 401.
  Widget _loginPrompt(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(returnResult: true),
                  ),
                );
                if (ok == true && mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    final loggedIn = ApiService().isLoggedIn;
    return [
      const MapScreen(),
      const SearchScreen(),
      const SizedBox(),
      loggedIn
          ? const RentalsScreen()
          : _loginPrompt(
              Icons.credit_card_outlined,
              'Здесь будут ваши аренды',
              'Войдите, чтобы бронировать инструменты и следить за арендами.',
            ),
      loggedIn
          ? const ProfileScreen()
          : _loginPrompt(
              Icons.person_outline,
              'Профиль',
              'Войдите, чтобы управлять аккаунтом и смотреть историю аренд.',
            ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        color: Colors.white,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabItem(0, Icons.home_outlined, Icons.home, 'Главная'),
          _tabItem(1, Icons.search, Icons.search, 'Поиск'),
          _qrButton(),
          _tabItem(3, Icons.credit_card_outlined, Icons.credit_card, 'Аренды'),
          _tabItem(4, Icons.person_outline, Icons.person, 'Профиль'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppTheme.primary : AppTheme.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrButton() {
    return GestureDetector(
      onTap: _onQrTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              'Сканер',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
