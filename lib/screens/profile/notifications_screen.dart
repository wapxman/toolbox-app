import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

/// Уведомления пользователя (GET /notifications). Открытие экрана помечает все прочитанными.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getNotifications();
      if (mounted) setState(() { _items = items; _loading = false; _error = null; });
      // Непрочитанные — помечаем прочитанными в фоне (ошибку игнорируем)
      if (items.any((n) => n['read'] != true)) {
        _api.markAllNotificationsRead().catchError((_) => <String, dynamic>{});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? e.message : 'Не удалось загрузить уведомления';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _message(Icons.cloud_off_outlined, _error!)
              : _items.isEmpty
                  ? _message(Icons.notifications_none, 'Уведомлений пока нет')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _card(_items[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'overdue':
      case 'overdue_fee':
        return AppTheme.error;
      case 'ending_soon':
      case 'reminder':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  String _when(String? iso) {
    final t = DateTime.tryParse(iso ?? '')?.toLocal();
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24 && t.day == now.day) return '${diff.inHours} ч назад';
    if (diff.inDays < 2) return 'Вчера';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
  }

  Widget _card(Map<String, dynamic> n) {
    final unread = n['read'] != true;
    final color = _colorFor(n['type']?.toString() ?? 'info');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderLight),
        color: unread ? const Color(0xFFFFF7F7) : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unread ? color : Colors.transparent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['title']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                    )),
                if ((n['message'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n['message'].toString(),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text(_when(n['sent_at']?.toString()),
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
