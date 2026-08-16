import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

/// «О приложении»: версия, ссылки на политику конфиденциальности,
/// пользовательское соглашение, поддержку и сайт.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Image.asset('assets/images/logo.png', height: 44),
                const SizedBox(height: 10),
                Text(
                  'Аренда электроинструмента 24/7 из умных боксов',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text('Версия $_version',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _item(Icons.privacy_tip_outlined, 'Политика конфиденциальности',
              () => _open(LegalLinks.privacy)),
          _item(Icons.description_outlined, 'Пользовательское соглашение (оферта)',
              () => _open(LegalLinks.terms)),
          _item(Icons.language, 'Сайт taketool.uz', () => _open(LegalLinks.site)),
          _item(Icons.mail_outline, 'Поддержка: ${LegalLinks.supportEmail}',
              () => _open('mailto:${LegalLinks.supportEmail}')),
          _item(Icons.phone_outlined, LegalLinks.supportPhone,
              () => _open('tel:${LegalLinks.supportPhone.replaceAll(' ', '')}')),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} AB PARTNERS MChJ, Ташкент, Узбекистан',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Icons.open_in_new, size: 18, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
