import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
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
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_tool == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('\u0418\u043d\u0441\u0442\u0440\u0443\u043c\u0435\u043d\u0442 \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d')));

    final tool = _tool!;
    final name = tool['name'] ?? '';
    final brand = tool['brand'] ?? '';
    final category = tool['category'] ?? '';
    final dayPrice = tool['day_price'] ?? 0;
    final specs = tool['specs'] as Map<String, dynamic>? ?? {};
    final available = (tool['cells']?['status'] ?? 'free') == 'free';
    final boxName = tool['cells']?['boxes']?['name'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, height: 200,
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.build, size: 64, color: AppTheme.textHint)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: available ? const Color(0xFFE6F7EE) : const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(999)),
              child: Text(available ? '\u0421\u0432\u043e\u0431\u043e\u0434\u0435\u043d' : '\u0417\u0430\u043d\u044f\u0442',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: available ? AppTheme.success : AppTheme.error)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$brand \u2022 $category', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF0FAF5), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('\u0421\u0442\u043e\u0438\u043c\u043e\u0441\u0442\u044c \u0430\u0440\u0435\u043d\u0434\u044b', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('$dayPrice \u0441\u045e\u043c / \u0434\u0435\u043d\u044c',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\u043e\u0442 3 \u0434\u043d\u0435\u0439', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                Text('-20%', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                Text('\u043e\u0442 7 \u0434\u043d\u0435\u0439', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                Text('-35%', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('\u0425\u0430\u0440\u0430\u043a\u0442\u0435\u0440\u0438\u0441\u0442\u0438\u043a\u0438', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...specs.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                Text(e.value.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            )),
          ],
        ]),
      ),
      bottomNavigationBar: available ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BookingScreen(
                toolName: name,
                pricePerDay: dayPrice is int ? dayPrice : int.tryParse(dayPrice.toString()) ?? 0,
                boxName: boxName,
              ),
            )),
            child: const Text('\u0410\u0440\u0435\u043d\u0434\u043e\u0432\u0430\u0442\u044c'),
          ),
        ),
      ) : null,
    );
  }
}
