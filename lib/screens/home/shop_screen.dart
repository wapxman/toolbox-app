import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import 'tool_detail_screen.dart';

/// Магазин: все инструменты всех боксов — в аренду и на продажу.
/// Гостю доступен без входа. Поиск здесь же (вкладка «Поиск» упразднена).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _api = ApiService();
  final _search = TextEditingController();
  Timer? _debounce;

  String _mode = 'rent'; // rent | buy
  String _category = '';
  List<dynamic> _tools = [];
  List<dynamic> _categories = [];
  int _deliveryFee = 50000;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeta();
    _load();
  }

  Future<void> _loadMeta() async {
    try {
      final results = await Future.wait([_api.getCategories(), _api.getDeliverySettings()]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<dynamic>;
        _deliveryFee = ((results[1] as Map<String, dynamic>)['fee'] ?? 50000) as int;
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tools = await _api.getCatalog(
        q: _search.text,
        category: _category,
        mode: _mode,
      );
      if (mounted) setState(() { _tools = tools; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Не удалось загрузить каталог'; });
    }
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Магазин')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            TextField(
              controller: _search,
              onChanged: _onQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Дрель, перфоратор, болгарка…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () { _search.clear(); _load(); },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            _modeSwitch(),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Все', ''),
                  ..._categories.map((c) => _chip(c.toString(), c.toString())),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(children: [
                const Icon(Icons.local_shipping_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                      children: [
                        const TextSpan(text: 'Доставка по Ташкенту — '),
                        TextSpan(
                          text: AppConstants.formatPrice(_deliveryFee),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ', самовывоз из бокса бесплатно'),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _modeSwitch() {
    Widget seg(String value, String label) {
      final active = _mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () { if (_mode != value) { setState(() => _mode = value); _load(); } },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: active
                  ? [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 3, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                )),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [seg('rent', 'Аренда'), seg('buy', 'Покупка')]),
    );
  }

  Widget _chip(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { setState(() => _category = value); _load(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppTheme.textPrimary,
              )),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: const Text('Повторить')),
      ]));
    }
    if (_tools.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 8),
        Text(_mode == 'buy' ? 'Пока ничего не продаётся' : 'Ничего не найдено',
            style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.66,
        ),
        itemCount: _tools.length,
        itemBuilder: (ctx, i) => _card(_tools[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _card(Map<String, dynamic> t) {
    final dayPrice = (t['day_price'] ?? 0) as int;
    final salePrice = t['sale_price'] as int?;
    final free = (t['cell_status'] ?? 'free') == 'free';
    final stock = (t['sale_stock'] ?? 0) as int;
    final buyMode = _mode == 'buy';
    final busyUntil = DateTime.tryParse(t['busy_until']?.toString() ?? '')?.toLocal();
    final busyText = busyUntil != null
        ? 'Занят до ${busyUntil.day.toString().padLeft(2, '0')}.${busyUntil.month.toString().padLeft(2, '0')}'
        : 'Занят';
    final big = _mode == 'buy' && salePrice != null
        ? AppConstants.formatPrice(salePrice)
        : '${AppConstants.formatPrice(dayPrice)}/день';
    final small = _mode == 'buy'
        ? 'Аренда: ${AppConstants.formatPrice(dayPrice)}/день'
        : (salePrice != null && (t['sale_stock'] ?? 0) > 0 ? 'Купить новый: ${AppConstants.formatPrice(salePrice)}' : 'Только аренда');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ToolDetailScreen(toolId: t['id'].toString()),
      )),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ToolPhoto(url: t['photo_url']?.toString(), width: double.infinity, height: 104, radius: 8, iconSize: 36),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Text(t['name']?.toString() ?? '',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
          ),
          const SizedBox(height: 6),
          Text(big, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(small, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (buyMode ? stock > 0 : free) ? const Color(0xFFE6F7EE) : const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
                buyMode ? (stock > 0 ? 'Новый · в наличии $stock шт.' : 'Нет в наличии') : (free ? 'Свободен' : busyText),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: (buyMode ? stock > 0 : free) ? AppTheme.success : AppTheme.error)),
          ),
        ]),
      ),
    );
  }
}
