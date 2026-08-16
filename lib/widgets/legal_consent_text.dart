import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// «Продолжая, вы принимаете Пользовательское соглашение и Политику конфиденциальности»
/// — показывается на экранах входа/регистрации (требование магазинов приложений).
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({super.key});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(
      color: AppTheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppTheme.primary,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 11.5, color: AppTheme.textHint, height: 1.4),
        children: [
          const TextSpan(text: 'Продолжая, вы принимаете '),
          TextSpan(
            text: 'Пользовательское соглашение',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => _open(LegalLinks.terms),
          ),
          const TextSpan(text: ' и '),
          TextSpan(
            text: 'Политику конфиденциальности',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => _open(LegalLinks.privacy),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
