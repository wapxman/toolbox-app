import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;

  // === AUTH ===

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isLoggedIn => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // === HTTP ===

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    ).timeout(ApiConfig.timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(ApiConfig.timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(ApiConfig.timeout);
    return _handleResponse(res);
  }

  Future<List<dynamic>> _getList(String path) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    ).timeout(ApiConfig.timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(res.statusCode, body['error'] ?? 'Ошибка сервера');
  }

  String _parseError(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error'] ?? 'Ошибка';
    } catch (_) {
      return 'Ошибка сервера';
    }
  }

  // === AUTH API ===

  Future<Map<String, dynamic>> sendCode(String phone) =>
    _post('/auth/send-code', {'phone': phone});

  Future<Map<String, dynamic>> verify(String phone, String code, {String? name}) async {
    final res = await _post('/auth/verify', {
      'phone': phone,
      'code': code,
      if (name != null) 'name': name,
    });
    if (res['token'] != null) await saveToken(res['token']);
    return res;
  }

  Future<Map<String, dynamic>> getMe() => _get('/auth/me');

  Future<Map<String, dynamic>> updateMe(String name) =>
    _patch('/auth/me', {'name': name});

  /// Удаление аккаунта (обезличивание на сервере). После успеха токен стирается.
  Future<Map<String, dynamic>> deleteAccount() async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers,
    ).timeout(ApiConfig.timeout);
    final body = _handleResponse(res);
    await clearToken();
    return body;
  }

  // === BOXES API ===

  Future<List<dynamic>> getBoxes() => _getList('/boxes');

  Future<Map<String, dynamic>> getBox(String id) => _get('/boxes/$id');

  Future<List<dynamic>> getBoxTools(String id) => _getList('/boxes/$id/tools');

  // === TOOLS API ===

  Future<List<dynamic>> searchTools(String query) =>
    _getList('/tools/search?q=$query');

  Future<Map<String, dynamic>> getTool(String id) => _get('/tools/$id');

  /// Каталог магазина: все инструменты всех боксов (аренда и продажа).
  Future<List<dynamic>> getCatalog({String? q, String? category, String? mode}) {
    final params = <String, String>{};
    if (q != null && q.trim().length >= 2) params['q'] = q.trim();
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (mode != null) params['mode'] = mode;
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return _getList('/tools$qs');
  }

  Future<List<dynamic>> getCategories() => _getList('/tools/categories');

  // === SETTINGS ===

  /// Тариф и интервалы доставки (публично, без входа).
  Future<Map<String, dynamic>> getDeliverySettings() => _get('/settings/delivery');

  // === RENTALS / ORDERS API ===

  Future<Map<String, dynamic>> createRental(String toolId, int days, {String provider = 'payme'}) =>
    _post('/rentals', {'tool_id': toolId, 'days': days, 'provider': provider});

  /// Заказ: аренда (kind=rent, days) или покупка (kind=buy),
  /// из бокса (fulfillment=pickup) или курьером (delivery + блок адреса).
  Future<Map<String, dynamic>> createOrder({
    required String toolId,
    required String kind,
    int days = 0,
    required String fulfillment,
    String provider = 'payme',
    Map<String, dynamic>? delivery,
  }) => _post('/rentals', {
    'tool_id': toolId,
    'kind': kind,
    'days': days,
    'fulfillment': fulfillment,
    'provider': provider,
    if (delivery != null) 'delivery': delivery,
  });

  /// Покупка с самовывозом: открыть ячейку с готовым заказом.
  Future<Map<String, dynamic>> pickupOrder(String id) => _post('/rentals/$id/pickup', {});

  /// Контакты поддержки (телефон, Telegram, e-mail) из настроек.
  Future<Map<String, dynamic>> getSupport() => _get('/settings/support');

  /// Отмена заказа клиентом (до передачи курьеру).
  Future<Map<String, dynamic>> cancelOrder(String id) => _post('/rentals/$id/cancel', {});

  /// Вызов курьера за арендованным инструментом (платно, создаёт дочерний заказ).
  Future<Map<String, dynamic>> returnByCourier(String id, {
    String provider = 'payme',
    required Map<String, dynamic> delivery,
  }) => _post('/rentals/$id/return-courier', {'provider': provider, 'delivery': delivery});

  Future<List<dynamic>> getActiveRentals() => _getList('/rentals/active');

  Future<List<dynamic>> getRentalHistory() => _getList('/rentals/history');

  Future<Map<String, dynamic>> getRental(String id) => _get('/rentals/$id');

  Future<Map<String, dynamic>> getPaymentStatus(String rentalId) =>
    _get('/rentals/$rentalId/payment-status');

  Future<Map<String, dynamic>> extendRental(String id, int extraDays) =>
    _post('/rentals/$id/extend', {'extra_days': extraDays});

  Future<Map<String, dynamic>> returnRental(String id) =>
    _post('/rentals/$id/return', {});

  // === NOTIFICATIONS API ===

  Future<List<dynamic>> getNotifications() => _getList('/notifications');

  Future<Map<String, dynamic>> markAllNotificationsRead() =>
    _patch('/notifications/read-all', {});

  // === LOCKS API ===

  Future<Map<String, dynamic>> getLockStatus() => _get('/locks/status');
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
