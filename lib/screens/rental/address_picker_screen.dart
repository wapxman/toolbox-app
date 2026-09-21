import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../core/theme.dart';

/// Точка доставки на Яндекс-карте: пин в центре, карта двигается под ним.
/// Возвращает {'lat','lng','address'}; адрес — обратное геокодирование MapKit.
class AddressPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const AddressPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  static const _tashkent = Point(latitude: 41.311081, longitude: 69.279737);
  // Границы Ташкента с запасом (весь город, без исключённых районов)
  static const _latMin = 41.16, _latMax = 41.44, _lngMin = 69.08, _lngMax = 69.48;

  YandexMapController? _controller;
  Point? _center;
  String? _address;
  bool _geocoding = false;
  Timer? _debounce;

  bool get _inCity =>
      _center != null &&
      _center!.latitude >= _latMin && _center!.latitude <= _latMax &&
      _center!.longitude >= _lngMin && _center!.longitude <= _lngMax;

  Point get _initial => (widget.initialLat != null && widget.initialLng != null)
      ? Point(latitude: widget.initialLat!, longitude: widget.initialLng!)
      : _tashkent;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onCamera(CameraPosition pos, CameraUpdateReason reason, bool finished) {
    _center = pos.target;
    if (!finished) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _geocode(pos.target));
  }

  Future<void> _geocode(Point p) async {
    setState(() { _geocoding = true; });
    String? found;
    try {
      final (session, resultFuture) = await YandexSearch.searchByPoint(
        point: p,
        zoom: 17,
        searchOptions: const SearchOptions(searchType: SearchType.geo, resultPageSize: 1),
      );
      final result = await resultFuture.timeout(const Duration(seconds: 8));
      final items = result.items ?? const <SearchItem>[];
      debugPrint('yandex search: found=${result.found} items=${items.length}');
      if (items.isNotEmpty) {
        found = items.first.toponymMetadata?.address.formattedAddress ?? items.first.name;
      }
      try { await session.close(); } catch (_) {}
    } catch (e) {
      debugPrint('yandex search error: $e');
      found = null;
    }
    // Запасной геокодер (OpenStreetMap Nominatim), если MapKit не отдал адрес
    if (found == null || found.trim().isEmpty) found = await _nominatim(p);
    if (!mounted) return;
    setState(() {
      _geocoding = false;
      _address = found ?? 'Точка ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    });
  }

  Future<String?> _nominatim(Point p) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}&accept-language=ru&zoom=18');
      final res = await http.get(uri, headers: {'User-Agent': 'Taketool/1.1 (support@taketool.uz)'}).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final a = (j['address'] as Map<String, dynamic>?) ?? {};
      final street = (a['road'] ?? a['pedestrian'] ?? a['residential'] ?? a['neighbourhood'] ?? '').toString();
      final house = (a['house_number'] ?? '').toString();
      final line = [street, house].where((x) => x.isNotEmpty).join(', ');
      return line.isNotEmpty ? line : (j['display_name']?.toString().split(',').take(2).join(',').trim());
    } catch (e) {
      debugPrint('nominatim error: $e');
      return null;
    }
  }

  void _done() {
    if (_center == null) return;
    Navigator.pop(context, {
      'lat': _center!.latitude,
      'lng': _center!.longitude,
      'address': _address ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Точка доставки')),
      body: Stack(children: [
        YandexMap(
          onMapCreated: (c) async {
            _controller = c;
            await c.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _initial, zoom: 15)));
            _center = _initial;
            _geocode(_initial);
          },
          onCameraPositionChanged: _onCamera,
        ),
        // Пин в центре экрана (карта двигается под ним)
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 44, color: AppTheme.primary,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]),
            ),
          ),
        ),
        Positioned(
          left: 16, right: 16, top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text('Передвиньте карту так, чтобы пин встал на ваш подъезд',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(Icons.place_outlined, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _geocoding ? 'Определяем адрес…' : (_address ?? 'Выберите точку на карте'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 2),
                  child: Text('Адрес по данным © OpenStreetMap; уточните подъезд в форме',
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                ),
                if (_center != null && !_inCity) ...[
                  const SizedBox(height: 8),
                  Text('Пока доставляем только по Ташкенту — точка вне города.',
                      style: TextStyle(fontSize: 13, color: AppTheme.error)),
                ],
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: (_center != null && _inCity && !_geocoding) ? _done : null,
                  child: const Text('Доставить сюда'),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
