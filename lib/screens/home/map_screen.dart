import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import 'box_detail_screen.dart';
import 'box_offline_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();
  List<dynamic> _boxes = [];
  bool _loading = true;
  YandexMapController? _mapController;

  // Ташкент по умолчанию, пока боксы не загрузились
  static const _defaultPoint = Point(latitude: 41.311081, longitude: 69.279737);

  @override
  void initState() {
    super.initState();
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    try {
      final boxes = await _api.getBoxes();
      if (mounted) setState(() { _boxes = boxes; _loading = false; });
      _moveToBoxes();
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _moveToBoxes() async {
    if (_mapController == null || _boxes.isEmpty) return;
    final first = _boxes.first;
    final lat = (first['lat'] as num?)?.toDouble();
    final lng = (first['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: Point(latitude: lat, longitude: lng), zoom: 13),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.8),
    );
  }

  List<PlacemarkMapObject> get _placemarks {
    final marks = <PlacemarkMapObject>[];
    for (final box in _boxes) {
      final lat = (box['lat'] as num?)?.toDouble();
      final lng = (box['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      marks.add(PlacemarkMapObject(
        mapId: MapObjectId('box_${box['id']}'),
        point: Point(latitude: lat, longitude: lng),
        opacity: 1,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/icons/map_pin.png'),
          scale: 0.9,
          anchor: const Offset(0.5, 1.0),
        )),
        onTap: (_, __) => _openBox(box),
      ));
    }
    return marks;
  }

  void _openBox(Map<String, dynamic> box) {
    final online = (box['status'] ?? 'online') == 'online';
    final name = box['name'] ?? 'Бокс';
    final address = box['address'] ?? '';
    if (online) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BoxDetailScreen(
          boxId: box['id'].toString(),
          boxName: name,
          address: address,
          online: true,
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BoxOfflineScreen(boxName: name, address: address),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _placemarks,
            onMapCreated: (controller) async {
              _mapController = controller;
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: _defaultPoint, zoom: 12),
                ),
              );
              _moveToBoxes();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textHint, size: 20),
                    const SizedBox(width: 10),
                    Text('Найти инструмент или бокс',
                      style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SizedBox(
              height: 120,
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _boxes.isEmpty
                  ? Center(child: Text('Боксы не найдены', style: TextStyle(color: AppTheme.textHint)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _boxes.length,
                      itemBuilder: (ctx, i) => _boxCard(ctx, _boxes[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxCard(BuildContext ctx, Map<String, dynamic> box) {
    final online = (box['status'] ?? 'online') == 'online';
    final name = box['name'] ?? 'Бокс';
    final address = box['address'] ?? '';
    final freeCells = box['free_cells'] ?? 0;
    final totalCells = box['cells_count'] ?? 0;

    return GestureDetector(
      onTap: () => _openBox(box),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: online ? AppTheme.primary : AppTheme.error)),
            ]),
            const SizedBox(height: 4),
            Text(address, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('$freeCells из $totalCells свободно',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
