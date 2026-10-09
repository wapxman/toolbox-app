import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Push-уведомления через Firebase Cloud Messaging.
///
/// Серверная часть (очередь `notification_outbox`, канал `push`, ключ
/// `FCM_SERVICE_ACCOUNT`) уже работает — приложению остаётся отдать свой токен.
///
/// ⚠️ Главное правило этого файла: **ни одна ошибка Firebase не должна ронять
/// приложение**. Оно уже опубликовано в обоих магазинах, и телефон без сервисов
/// Google, запрет уведомлений или отвалившаяся сеть — это норма, а не авария.
/// Поэтому всё обёрнуто в try/catch, а неудача молча выключает пуши.
class PushService {
  static final PushService _instance = PushService._();
  factory PushService() => _instance;
  PushService._();

  bool _ready = false;
  String? _token;

  /// Токен этого телефона, если его удалось получить.
  String? get token => _token;

  /// Поднять Firebase. Зовётся один раз из main() ДО runApp.
  /// Возвращает false, если Firebase недоступен — приложение работает дальше.
  Future<bool> init() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      _ready = true;
      // Токен может смениться сам (переустановка, очистка данных, ротация).
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        _token = t;
        await _sendToBackend();
      });
      return true;
    } catch (e) {
      debugPrint('[push] Firebase не поднялся, пуши выключены: $e');
      return false;
    }
  }

  /// Спросить разрешение и получить токен. Зовём ПОСЛЕ входа пользователя:
  /// до него токен серверу всё равно некуда привязать (ручка под авторизацией).
  Future<void> registerIfLoggedIn() async {
    if (!_ready || !ApiService().isLoggedIn) return;
    try {
      // На iOS без этого токена не будет вовсе; на Android 13+ это системный
      // диалог POST_NOTIFICATIONS, на более старых — no-op.
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[push] пользователь запретил уведомления');
        return;
      }
      _token = await FirebaseMessaging.instance.getToken();
      await _sendToBackend();
    } catch (e) {
      debugPrint('[push] не удалось получить токен: $e');
    }
  }

  Future<void> _sendToBackend() async {
    final t = _token;
    if (t == null || t.isEmpty || !ApiService().isLoggedIn) return;
    try {
      await ApiService().registerDevice(t, Platform.isIOS ? 'ios' : 'android');
      debugPrint('[push] устройство зарегистрировано');
    } catch (e) {
      // Сеть или 5xx — не беда: отправим при следующем запуске.
      debugPrint('[push] регистрация устройства не прошла: $e');
    }
  }

  /// Снять устройство при выходе из аккаунта. Иначе следующий человек на этом
  /// же телефоне получит чужие уведомления.
  Future<void> unregister() async {
    final t = _token;
    if (t == null || t.isEmpty) return;
    try {
      await ApiService().unregisterDevice(t);
    } catch (e) {
      debugPrint('[push] снять устройство не вышло: $e');
    }
  }
}
