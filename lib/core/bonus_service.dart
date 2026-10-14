// Бонусный счёт — один на всё приложение.
//
// Бонус показывается в трёх местах сразу: полосой на главной, скидкой на цене
// в магазине и картой в профиле. Если бы каждый экран спрашивал сервер сам,
// получилось бы три запроса на один вход и три разные цифры на одном экране в
// момент обновления. Поэтому счёт живёт здесь, а экраны на него подписаны.
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class BonusService extends ChangeNotifier {
  static final BonusService _i = BonusService._();
  factory BonusService() => _i;
  BonusService._();

  int _balance = 0;
  int _maxPayPct = 50;
  DateTime? _expiresAt;
  bool _loaded = false;
  Future<void>? _inFlight;

  int get balance => _balance;
  int get maxPayPct => _maxPayPct;
  DateTime? get expiresAt => _expiresAt;
  bool get hasBonus => _loaded && _balance > 0;

  /// Сколько бонуса уйдёт в счёт покупки на [itemsPrice].
  ///
  /// Та же формула, что на сервере, но решение всё равно за ним: здесь это
  /// только предпросмотр цены в списке товаров. Расхождение невозможно, пока
  /// обе стороны считают от суммы товаров и одного потолка.
  int applicableTo(int itemsPrice) {
    if (!hasBonus || itemsPrice <= 0) return 0;
    final cap = (itemsPrice * _maxPayPct) ~/ 100;
    return _balance < cap ? _balance : cap;
  }

  /// Сколько дней осталось до сгорания ближайшего начисления.
  int? get daysLeft {
    if (_expiresAt == null) return null;
    final d = _expiresAt!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  /// Обновить счёт. Параллельные вызовы схлопываются в один запрос — экраны
  /// зовут refresh наперебой, и три одинаковых запроса здесь ни к чему.
  Future<void> refresh() {
    if (_inFlight != null) return _inFlight!;
    final f = _load().whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  Future<void> _load() async {
    if (!ApiService().isLoggedIn) {
      // Гость: счёта нет, но и ошибки нет — просто нечего показывать.
      _reset();
      return;
    }
    try {
      final d = await ApiService().getBonusBalance();
      _balance = (d['balance'] ?? 0) as int;
      _maxPayPct = (d['max_pay_pct'] ?? 50) as int;
      final raw = d['expires_at']?.toString();
      _expiresAt = (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Молчим: не смогли узнать баланс — просто не показываем плашку.
      // Ошибка сети не повод пугать человека на главном экране.
    }
  }

  /// Забыть счёт — при выходе из аккаунта. Иначе следующий вошедший увидит
  /// чужие деньги, пока не придёт ответ сервера.
  void forget() => _reset();

  void _reset() {
    final had = _loaded || _balance != 0;
    _balance = 0;
    _expiresAt = null;
    _loaded = false;
    if (had) notifyListeners();
  }
}
