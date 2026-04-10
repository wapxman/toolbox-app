import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'home/box_detail_screen.dart';
import 'home/box_offline_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();
  List<dynamic> _boxes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    try {
      final boxes = await _api.getBoxes();
      if (mounted) setState(() { _boxes = boxes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFE8E8E0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 48, color: AppTheme.textHint),
                  const SizedBox(height: 8),
                  Text('Карта боксов', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_loading ? 'Загрузка...' : '${_boxes.length} боксов найдено',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
            ),
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
    final online = box['is_active'] ?? true;
    final name = box['name'] ?? 'Бокс';
    final address = box['address'] ?? '';
    final freeCells = box['free_cells'] ?? 0;
    final totalCells = box['total_cells'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (online) {
          Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => BoxDetailScreen(
              boxId: box['id'].toString(),
              boxName: name,
              address: address,
              online: true,
            ),
          ));
        } else {
          Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => BoxOfflineScreen(boxName: name, address: address),
          ));
        }
      },
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
