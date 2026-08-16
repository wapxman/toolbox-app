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

  // === RENTALS API ===

  Future<Map<String, dynamic>> createRental(String toolId, int days, {String provider = 'payme'}) =>
    _post('/rentals', {'tool_id': toolId, 'days': days, 'provider': provider});

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
