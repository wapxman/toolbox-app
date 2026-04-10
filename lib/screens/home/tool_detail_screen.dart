import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../rental/booking_screen.dart';

class ToolDetailScreen extends StatefulWidget {
  final String toolId;
  const ToolDetailScreen({super.key, required this.toolId});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _tool;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTool();
  }

  Future<void> _loadTool() async {
    try {
      final tool = await _api.getTool(widget.toolId);
      if (mounted) setState(() { _tool = tool; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_tool == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Инструмент не найден')),
      );
    }

    final tool = _tool!;
    final name = tool['name'] ?? '';
    final brand = tool['brand'] ?? '';
    final category = tool['category'] ?? '';
    final dayPrice = tool['day_price'] ?? 0;
    final specs = tool['specs'] as Map<String, dynamic>? ?? {};
    final available = (tool['cells']?['status'] ?? 'free') == 'free';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: tool['photo_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(tool['photo_url'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.build, size: 64, color: AppTheme.textHint)),
                  )
                : Icon(Icons.build, size: 64, color: AppTheme.textHint),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? const Color(0xFFE6F7EE) : const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(available ? 'Свободен' : 'Занят',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: available ? AppTheme.success : AppTheme.error)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('$brand • $category', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Стоимость аренды', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('$dayPrice сўм / день',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('от 3 дней', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                  Text('-20%', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  Text('от 7 дней', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                  Text('-35%', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Характеристики', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...specs.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                  Text(e.value.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              )),
            ],
          ],
        ),
      ),
      bottomNavigationBar: available ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BookingScreen(tool: tool),
            )),
            child: const Text('Арендовать'),
          ),
        ),
      ) : null,
    );
  }
}
