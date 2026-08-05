import 'package:flutter/material.dart';
import '../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _Noti('Аренда создана', 'Дрель Bosch GSB 13 RE — 3 дня', '2 мин назад', AppTheme.primary, true),
      _Noti('Оплата прошла', '192 000 сўм через Payme', '2 мин назад', AppTheme.primary, true),
      _Noti('Аренда заканчивается', 'Шуруповёрт Makita — завтра в 14:00', '1 час назад', AppTheme.warning, true),
      _Noti('Аренда просрочена!', 'Болгарка DeWalt — просрочка 2 дня', 'Вчера', AppTheme.error, false),
      _Noti('Добро пожаловать!', 'Добро пожаловать в Taketool', '3 апр', AppTheme.primary, false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = notifications[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borderLight),
              color: n.unread ? const Color(0xFFF9FFFE) : Colors.white,
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
                    color: n.unread ? n.color : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: n.unread ? FontWeight.w600 : FontWeight.w500,
                          )),
                      const SizedBox(height: 2),
                      Text(n.body,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text(n.time,
                          style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Noti {
  final String title, body, time;
  final Color color;
  final bool unread;
  _Noti(this.title, this.body, this.time, this.color, this.unread);
}
