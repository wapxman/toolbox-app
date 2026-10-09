import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import '../screens/home/box_detail_screen.dart';

/// Ссылки вида https://taketool.uz/dl/box?b=<uuid бокса> — тот самый QR,
/// что наклеен на шкаф.
///
/// Зачем: без этого человек с уже установленным приложением, наведя камеру
/// телефона на QR, попадал в магазин приложений вместо экрана шкафа.
/// Теперь система сама поднимает приложение (App Links на Android,
/// Universal Links на iOS), а мы открываем нужный бокс.
///
/// ⚠️ Как и в PushService: ни одна ошибка здесь не должна ронять приложение.
/// Плохая ссылка, нет сети, бокс удалён — просто ничего не происходит.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  final _links = AppLinks();
  GlobalKey<NavigatorState>? _navKey;

  /// Тот же разбор, что в сканере QR: берём первый UUID из строки.
  /// Namespace сознательно не проверяем — формат ссылки может поменяться,
  /// а UUID бокса в ней останется.
  static String? extractBoxId(String raw) {
    final m = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(raw);
    return m?.group(0);
  }

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    _navKey = navKey;
    try {
      // Ссылка, которой приложение запустили из холодного старта.
      final initial = await _links.getInitialLink();
      if (initial != null) _handle(initial);
      // И все последующие, пока приложение живо.
      _links.uriLinkStream.listen(_handle, onError: (_) {});
    } catch (e) {
      debugPrint('[deeplink] не поднялось: $e');
    }
  }

  Future<void> _handle(Uri uri) async {
    final boxId = extractBoxId(uri.toString());
    if (boxId == null) return;
    final nav = _navKey?.currentState;
    if (nav == null) return;
    try {
      final box = await ApiService().getBox(boxId);
      nav.push(MaterialPageRoute(
        builder: (_) => BoxDetailScreen(
          boxId: box['id'].toString(),
          boxName: box['name'] ?? 'Бокс',
          address: box['address'] ?? '',
          online: (box['status'] ?? 'online') == 'online',
        ),
      ));
    } catch (e) {
      debugPrint('[deeplink] бокс $boxId не открылся: $e');
    }
  }
}
