// Колесо Фортуны.
//
// ⚠️ ПРИЗ ВЫБИРАЕТ СЕРВЕР. Здесь нет ни весов, ни случайного выбора приза:
// экран просит прокрутить, получает готовый результат и доворачивает колесо
// так, чтобы стрелка встала на выпавший сектор. Если бы приз выбирался тут,
// подмена одного ответа давала бы главный приз кому угодно.
//
// Анимация поэтому идёт ПОСЛЕ ответа сервера: сначала узнаём приз, потом
// крутим. Задержка сети прячется внутрь раскрутки — человек её не замечает.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../auth/register_screen.dart';
import 'coin_flight.dart';
import 'wheel_entry.dart';
import 'wheel_rules_screen.dart';
import 'wallet_screen.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final AnimationController _ctrl;
  late Animation<double> _turns;

  bool _loading = true;
  String? _error;
  bool _spinning = false;

  bool _enabled = true;
  int _spinsLeft = 0;
  int _balance = 0;
  int _expiresDays = 30;
  int _maxPayPct = 50;
  List<Map<String, dynamic>> _prizes = [];

  /// Раскладка колеса: коды призов по кругу. Её считает сервер из весов, здесь
  /// её только рисуют. Дешёвый приз встречается несколько раз, дорогой — один.
  List<String> _sectors = [];

  /// Крутит гость — приз зачислится только после регистрации. Об этом обязаны
  /// предупредить ДО прокрутки, иначе выйдет ловушка: человек выигрывает и
  /// только потом узнаёт про условие.
  bool _requiresAccount = false;

  /// Куда летят монетки — иконка кошелька в шапке.
  final _walletKey = GlobalKey();

  /// Правила акции: число победителей, срок, условия. Приходят с сервера,
  /// чтобы текст правил и поведение кода не разъехались.
  Map<String, dynamic> _rules = {};

  /// С какой суммы докручивать счётчик. Цифра должна ожить в момент прилёта
  /// монет, а не прыгнуть — иначе связь «выиграл → деньги здесь» распадается.
  int _balanceFrom = 0;

  double _angle = 0; // текущий угол в оборотах

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _turns = AlwaysStoppedAnimation(0);
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await _api.getWheel();
      setState(() {
        _enabled = d['enabled'] == true;
        _spinsLeft = (d['spins_left'] ?? 0) as int;
        _balance = (d['balance'] ?? 0) as int;
        _expiresDays = (d['expires_days'] ?? 30) as int;
        _maxPayPct = (d['max_pay_pct'] ?? 50) as int;
        _prizes = ((d['prizes'] ?? []) as List).cast<Map<String, dynamic>>();
        _requiresAccount = d['requires_account'] == true;
        _rules = ((d['rules'] ?? {}) as Map).cast<String, dynamic>();
        _sectors = ((d['sectors'] ?? []) as List).map((e) => e.toString()).toList();
        // Старый сервер раскладки не отдаёт — тогда сектор на приз, как было.
        if (_sectors.isEmpty) {
          _sectors = _prizes.map((p) => p['code'].toString()).toList();
        }
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = _human(e); _loading = false; });
    }
  }

  String _human(Object e) {
    final s = e is ApiException ? e.message : e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  Future<void> _spin() async {
    if (_spinning || _prizes.isEmpty) return;
    setState(() { _spinning = true; });

    Map<String, dynamic> prize;
    bool pending;
    try {
      final d = await _api.spinWheel();
      prize = (d['prize'] as Map).cast<String, dynamic>();
      _balance = (d['balance'] ?? _balance) as int;
      pending = d['pending'] == true; // крутил гость — приз ждёт регистрации
    } catch (e) {
      setState(() { _spinning = false; });
      if (mounted) _say(_human(e));
      return;
    }

    // Доворачиваем колесо на выпавший сектор. Сектор ищем по коду, а не по
    // индексу: порядок призов на сервере может измениться.
    // Выпавший приз занимает несколько секторов — встаём на случайный из них,
    // иначе колесо всегда замирает в одном и том же месте и это заметно.
    final hits = <int>[];
    for (var i = 0; i < _sectors.length; i++) {
      if (_sectors[i] == prize['code']) hits.add(i);
    }
    final idx = hits.isEmpty ? -1 : hits[math.Random().nextInt(hits.length)];
    final n = _sectors.length;
    final seg = 1.0 / n;
    // Сектор idx painter рисует с центром на угле idx*seg от стрелки, поэтому
    // доворот — ровно -(idx*seg), без полусектора: иначе стрелка встаёт на
    // границу и джиттер уводит её в соседний сектор.
    //
    // Если код приза в списке не нашёлся (idx == -1), доворачивать некуда —
    // крутим на целое число оборотов и показываем результат как есть.
    final jitter = (math.Random().nextDouble() - 0.5) * seg * 0.6;
    final target = idx < 0 ? 0.0 : -(idx * seg + jitter);
    final full = 6 + math.Random().nextInt(2); // полных оборотов для разгона
    final end = _angle.floorToDouble() + full + target;

    _turns = Tween<double>(begin: _angle, end: end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _ctrl.reset();
    await _ctrl.forward();
    _angle = end;

    if (!mounted) return;
    // Покрутил — звать его в акцию больше не нужно.
    WheelPromo.markSpun();
    setState(() {
      _spinning = false;
      _spinsLeft = _spinsLeft > 0 ? _spinsLeft - 1 : 0;
    });
    _showWin(prize, pending);
  }

  void _say(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// Гость забирает выигрыш: монетки улетают в кошелёк, следом открывается
  /// регистрация. Порядок именно такой — сперва человек видит, что приз ушёл
  /// на его счёт, и только потом его просят завести аккаунт. Наоборот было бы
  /// «заплати, потом покажем».
  Future<void> _claimAsGuest(int amount) async {
    final box = _walletKey.currentContext?.findRenderObject() as RenderBox?;
    final screen = MediaQuery.of(context).size;
    final to = box != null
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset(screen.width - 36, 60);

    await CoinFlight.play(
      context,
      from: Offset(screen.width / 2, screen.height * 0.42),
      to: to,
      onArrive: () {
        if (!mounted || amount <= 0) return;
        setState(() {
          _balanceFrom = _balance;
          _balance += amount;
        });
      },
    );
    if (!mounted) return;

    // Экран регистрации. Вернулся с успехом — забираем приз с сервера:
    // до этого момента он числился за устройством, а не за человеком.
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen(returnResult: true)),
    );
    if (ok == true && mounted) {
      try {
        await _api.claimWheelPrize();
      } catch (_) {
        // Молчим намеренно: приз никуда не делся, он привяжется при следующем
        // заходе на экран. Ругаться на человека за нашу сетевую ошибку незачем.
      }
      if (mounted) _load();
    }
  }

  void _showWin(Map<String, dynamic> prize, bool pending) {
    final isItem = prize['kind'] == 'item';
    final amount = (prize['amount'] ?? 0) as int;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.1), shape: BoxShape.circle),
              child: Icon(isItem ? Icons.handyman : Icons.card_giftcard, color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Поздравляем!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              prize['label']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              pending
                  ? (isItem
                      ? 'Приз закреплён за вами. Зарегистрируйтесь, чтобы мы '
                        'знали, кому его вручить в пункте выдачи.'
                      : 'Зарегистрируйтесь, чтобы забрать бонус на счёт. '
                        'Он действует $_expiresDays дней и покрывает до '
                        '$_maxPayPct% стоимости аренды.')
                  : (isItem
                      ? 'Приз вручается в пункте выдачи. Мы свяжемся с вами.'
                      : 'Бонус зачислен на счёт. Действует $_expiresDays дней и покрывает '
                        'до $_maxPayPct% стоимости аренды.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (pending) {
                    _claimAsGuest(isItem ? 0 : amount);
                  } else if (!isItem && amount > 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  }
                },
                child: Text(
                  pending
                      ? 'Забрать приз'
                      : (isItem ? 'Понятно' : 'Открыть кошелёк'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Колесо Фортуны'),
        actions: [
          IconButton(
            key: _walletKey, // сюда летят монетки
            tooltip: 'Кошелёк',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _content(),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off, size: 40, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: _load, child: const Text('Повторить')),
          ]),
        ),
      );

  Widget _content() {
    final canSpin = _enabled && _spinsLeft > 0 && !_spinning;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(children: [
        Text('Крутите и забирайте бонус на аренду',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4)),
        const SizedBox(height: 18),

        // ---- колесо ----
        SizedBox(
          width: 300, height: 320,
          child: Stack(alignment: Alignment.topCenter, children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.rotate(
                  angle: (_ctrl.isAnimating ? _turns.value : _angle) * 2 * math.pi,
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _WheelPainter(_sectors, {
                    for (final p in _prizes)
                      p['code'].toString(): p['label']?.toString() ?? '',
                  }),
                ),
              ),
            ),
            // Стрелка сверху
            Positioned(
              top: 0,
              child: CustomPaint(size: const Size(26, 30), painter: _PointerPainter()),
            ),
          ]),
        ),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: canSpin ? AppTheme.primary : AppTheme.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            onPressed: canSpin ? _spin : null,
            child: Text(
              _spinning
                  ? 'Крутим…'
                  : !_enabled
                      ? 'Акция завершена'
                      : _spinsLeft > 0
                          ? 'Крутить'
                          : 'Попытка использована',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _spinsLeft > 0 ? 'У вас $_spinsLeft попытка' : 'Попытка даётся один раз',
          style: TextStyle(fontSize: 12, color: AppTheme.textHint),
        ),

        // ⚠️ Условие объявляем ДО прокрутки. Если сказать о регистрации только
        // после выигрыша, механика читается как обман — ровно так работают
        // мошеннические «покрути колесо» всплывашки, и недоверие переносится
        // на нас. Сказанное заранее — честная сделка.
        if (_requiresAccount) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Приз зачислится на счёт после регистрации',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ]),
        ],

        const SizedBox(height: 20),
        _balanceCard(),
        const SizedBox(height: 18),
        _prizeList(),
        const SizedBox(height: 14),
        Text(
          'Бонус начисляется на счёт в приложении, действует $_expiresDays дней '
          'и покрывает до $_maxPayPct% стоимости аренды. На доставку не распространяется. '
          'Инструменты выдаются по запросу.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.textHint, height: 1.5),
        ),
        const SizedBox(height: 4),
        // Ссылку на правила держим на виду, а не прячем: это и требование
        // магазинов, и то, из-за чего колесо перестаёт выглядеть разводом.
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WheelRulesScreen(rules: _rules, prizes: _prizes),
            ),
          ),
          child: const Text('Правила акции',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _balanceCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(children: [
          Icon(Icons.account_balance_wallet, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Бонусный счёт', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              AnimatedAmount(
                from: _balanceFrom,
                to: _balance,
                format: AppConstants.formatPrice,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ]),
          ),
          TextButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: const Text('История'),
          ),
        ]),
      );

  Widget _prizeList() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ПРИЗОВОЙ ФОНД',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                letterSpacing: 1.2, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        ..._prizes.map((p) {
          final isItem = p['kind'] == 'item';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(isItem ? .12 : .06),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(isItem ? Icons.handyman : Icons.payments_outlined,
                    size: 19, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['label']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(isItem ? 'Ценный приз' : 'Бонус на аренду',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ),
              if (isItem)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: const Text('главный',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
            ]),
          );
        }),
      ]);
}

/// Сектора колеса. Чередование красный/чёрный/белый — фирменная палитра.
/// Рисуем по раскладке с сервера: один и тот же приз может стоять несколько раз.
class _WheelPainter extends CustomPainter {
  final List<String> sectors;
  final Map<String, String> labels;
  _WheelPainter(this.sectors, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    if (sectors.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final n = sectors.length;
    final sweep = 2 * math.pi / n;

    const colors = [Color(0xFFDC0000), Color(0xFF0D0D0D), Colors.white];

    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      final paint = Paint()..color = colors[i % colors.length]..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, true, paint);

      // Подпись вдоль радиуса. Чем больше секторов, тем они уже — и тем мельче
      // должен быть шрифт, иначе соседние подписи налезают друг на друга.
      final label = labels[sectors[i]] ?? '';
      final isWhite = (i % colors.length) == 2;
      final fit = sweep * r * 0.42; // высота, которую сектор даёт под строку
      final base = label.length > 12 ? 10.0 : 12.0;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: math.max(7.0, math.min(base, fit)),
            fontWeight: FontWeight.w800,
            color: isWhite ? const Color(0xFF0D0D0D) : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(maxWidth: r * 0.72);

      // Подпись лежит вдоль радиуса. В нижней и левой половине круга это
      // направление уводит буквы вверх ногами, поэтому там разворачиваем
      // текст и ведём его от обода к центру.
      final a = start + sweep / 2;
      final norm = (a % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
      final flip = norm >= math.pi / 2 && norm < 3 * math.pi / 2;

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(flip ? a + math.pi : a);
      tp.paint(
        canvas,
        flip
            ? Offset(-r * 0.26 - tp.width, -tp.height / 2)
            : Offset(r * 0.26, -tp.height / 2),
      );
      canvas.restore();
    }

    // Обод и ступица
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 7..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(c, r * 0.19, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.19, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF0D0D0D));
    final t = TextPainter(
      text: const TextSpan(
          text: 'T',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFDC0000))),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(canvas, c - Offset(t.width / 2, t.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.sectors != sectors;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF0D0D0D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
