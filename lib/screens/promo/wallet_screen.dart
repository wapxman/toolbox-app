// Бонусный кошелёк: баланс и история движений.
//
// Баланс приходит с сервера и здесь НЕ пересчитывается. Сложить движения на
// телефоне кажется проще, но тогда сгоревший бонус останется в сумме: срок
// сгорания знает только сервер, он и считает.
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  int _balance = 0;
  int _maxPayPct = 50;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await _api.getWallet();
      setState(() {
        _balance = (d['balance'] ?? 0) as int;
        _maxPayPct = (d['max_pay_pct'] ?? 50) as int;
        _entries = ((d['entries'] ?? []) as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      final s = e is ApiException ? e.message : e.toString();
      setState(() { _error = s.replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'wheel_win': return 'Выигрыш в колесе';
      case 'rent_spend': return 'Списано на заказ';
      case 'refund': return 'Возврат при отмене';
      case 'manual': return 'Начисление';
      default: return kind;
    }
  }

  String _date(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Бонусный счёт')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 14),
                      OutlinedButton(onPressed: _load, child: const Text('Повторить')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      if (_entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('Движений пока нет',
                                style: TextStyle(color: AppTheme.textHint)),
                          ),
                        )
                      else ...[
                        Text('ИСТОРИЯ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                letterSpacing: 1.2, color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        ..._entries.map(_row),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Доступно', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(AppConstants.formatPrice(_balance),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            'Покрывает до $_maxPayPct% стоимости аренды. На доставку не распространяется.',
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
        ]),
      );

  Widget _row(Map<String, dynamic> e) {
    final amount = (e['amount'] ?? 0) as int;
    final plus = amount > 0;
    final expires = e['expires_at'] as String?;
    final expired = expires != null &&
        (DateTime.tryParse(expires)?.isBefore(DateTime.now()) ?? false);

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
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: (plus ? AppTheme.success : AppTheme.textHint).withOpacity(.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(plus ? Icons.add : Icons.remove,
              size: 18, color: plus ? AppTheme.success : AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e['note']?.toString().isNotEmpty == true
                    ? e['note'].toString()
                    : _kindLabel(e['kind']?.toString() ?? ''),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              [
                _date(e['created_at'] as String?),
                if (expires != null && plus)
                  expired ? 'срок истёк' : 'действует до ${_date(expires)}',
              ].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(
                fontSize: 11,
                color: expired ? AppTheme.error : AppTheme.textSecondary,
              ),
            ),
          ]),
        ),
        Text(
          '${plus ? '+' : '−'}${AppConstants.formatPrice(amount.abs())}',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: plus ? AppTheme.success : AppTheme.textPrimary,
          ),
        ),
      ]),
    );
  }
}
