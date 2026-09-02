import 'package:shared_preferences/shared_preferences.dart';

/// Локальные флаги приложения, не связанные с авторизацией.
class AppPrefs {
  /// Помечает, что приветствие/онбординг уже показывали.
  /// После этого приложение всегда стартует прямо с каталога —
  /// каталог не должен требовать регистрации (Guideline 5.1.1(v)).
  static Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
  }
}
