import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

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
                    Navigator.pushNamed(context, '/history');
                  }),
                  _menuItem(Icons.notifications_outlined, 'Уведомления', () {
                    Navigator.pushNamed(context, '/notifications');
                  }),
                  _menuItem(Icons.info_outline, 'О приложении', () {}),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _api.clearToken();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                        }
                      },
                      child: const Text('Выйти', style: TextStyle(color: Colors.red)),
                    ),
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
