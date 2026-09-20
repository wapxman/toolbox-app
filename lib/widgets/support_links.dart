import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Контакты поддержки из app_settings.support (телефон, Telegram, e-mail).
/// Грузятся один раз за сессию; при ошибке — телефон из констант.
class SupportLinks {
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> load() async {
    if (_cache != null) return _cache!;
    try {
      _cache = await ApiService().getSupport();
    } catch (_) {
      _cache = {'phone': LegalLinks.supportPhone, 'telegram': null, 'email': LegalLinks.supportEmail};
    }
    return _cache!;
  }

  static Future<void> open(String url) async {
    try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  static String telegramUrl(String v) {
    final t = v.trim();
    if (t.startsWith('http')) return t;
    return 'https://t.me/${t.replaceFirst('@', '')}';
  }
}

/// Кнопки «Позвонить» / «Telegram» / «Написать» в одну строку. Пустые контакты не показываются.
class SupportButtons extends StatelessWidget {
  final String? caption;
  const SupportButtons({super.key, this.caption});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SupportLinks.load(),
      builder: (context, snap) {
        final s = snap.data ?? {};
        final phone = (s['phone'] ?? '').toString();
        final tg = (s['telegram'] ?? '').toString();
        final email = (s['email'] ?? '').toString();
        final buttons = <Widget>[
          if (phone.isNotEmpty)
            _btn(Icons.phone_outlined, 'Позвонить', () => SupportLinks.open('tel:${phone.replaceAll(' ', '')}')),
          if (tg.isNotEmpty)
            _btn(Icons.send_outlined, 'Telegram', () => SupportLinks.open(SupportLinks.telegramUrl(tg))),
          if (email.isNotEmpty)
            _btn(Icons.mail_outline, 'Написать', () => SupportLinks.open('mailto:$email')),
        ];
        if (buttons.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (caption != null) ...[
            Text(caption!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
            const SizedBox(height: 8),
          ],
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ]);
      },
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 14)),
      );
}
