import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../welcome_screen.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _api.getMe();
      if (mounted) setState(() { _user = user; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _goToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (mounted) _goToWelcome();
  }

  // Удаление аккаунта — требование Google Play / App Store.
  // Сервер обезличивает данные; при открытых арендах вернёт 409 с пояснением.
  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Ваш номер телефона и имя будут удалены, войти в этот аккаунт станет невозможно. '
          'История завершённых аренд сохранится в обезличенном виде для бухгалтерии.\n\n'
          'Перед удалением верните инструмент и закройте активные аренды.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await _api.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт удалён')),
      );
      _goToWelcome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Не удалось удалить аккаунт'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _user == null
          ? const Center(child: Text('Не удалось загрузить профиль'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      (_user!['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_user!['name'] ?? 'Пользователь',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_user!['phone'] ?? '',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  _statsRow(),
                  const SizedBox(height: 24),
                  _menuItem(Icons.history, 'История аренд', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  }),
                  _menuItem(Icons.notifications_outlined, 'Уведомления', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }),
                  _menuItem(Icons.info_outline, 'О приложении', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()));
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Выйти', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _confirmDeleteAccount,
                    child: Text('Удалить аккаунт',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statsRow() {
    final stats = _user!['stats'] as Map<String, dynamic>? ?? {};
    return Row(
      children: [
        _statCard('Всего аренд', '${stats['total_rentals'] ?? 0}'),
        const SizedBox(width: 10),
        _statCard('Активных', '${stats['active_rentals'] ?? 0}'),
        const SizedBox(width: 10),
        _statCard('Потрачено', '${stats['total_spent'] ?? 0} сўм'),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
