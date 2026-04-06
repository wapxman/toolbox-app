import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'box_detail_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: const Color(0xFFE8E8E0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 48, color: AppTheme.textHint),
                  const SizedBox(height: 8),
                  Text(
                    'Карта загружается...',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Google Maps будет подключён позже',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ],
              ),
            ),
          ),
          // Search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textHint, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Найти инструмент или бокс',
                      style: TextStyle(fontSize: 13, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Box cards
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _boxCard(context, 'ToolBox #1', 'ТЦ Samarqand Darvoza', '12 инструментов', true),
                  _boxCard(context, 'ToolBox #2', 'Строймаркет Чиланзар', '8 инструментов', true),
                  _boxCard(context, 'ToolBox #3', 'ТЦ Mega Planet', '5 инструментов', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxCard(BuildContext context, String name, String address, String tools, bool online) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoxDetailScreen(
              boxName: name,
              address: address,
              online: online,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? AppTheme.primary : AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(tools, style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
