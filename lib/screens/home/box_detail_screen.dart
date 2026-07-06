import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import 'tool_detail_screen.dart';

class BoxDetailScreen extends StatefulWidget {
  final String boxId;
  final String boxName;
  final String address;
  final bool online;

  const BoxDetailScreen({
    super.key,
    required this.boxId,
    required this.boxName,
    required this.address,
    required this.online,
  });

  @override
  State<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends State<BoxDetailScreen> {
  final _api = ApiService();
  List<dynamic> _tools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    try {
      final tools = await _api.getBoxTools(widget.boxId);
      if (mounted) setState(() { _tools = tools; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.boxName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(widget.address,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: widget.online ? AppTheme.primary : AppTheme.error)),
              const SizedBox(width: 6),
              Text(widget.online ? '\u041e\u043d\u043b\u0430\u0439\u043d' : '\u041e\u0444\u0444\u043b\u0430\u0439\u043d',
                style: TextStyle(fontSize: 12,
                  color: widget.online ? AppTheme.primary : AppTheme.error,
                  fontWeight: FontWeight.w500)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('\u0418\u043d\u0441\u0442\u0440\u0443\u043c\u0435\u043d\u0442\u044b',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tools.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.construction, size: 48, color: AppTheme.textHint),
                    const SizedBox(height: 8),
                    Text('\u041d\u0435\u0442 \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0445 \u0438\u043d\u0441\u0442\u0440\u0443\u043c\u0435\u043d\u0442\u043e\u0432',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tools.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _toolCard(ctx, _tools[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(BuildContext ctx, Map<String, dynamic> tool) {
    final name = tool['name'] ?? '';
    final brand = tool['brand'] ?? '';
    final category = tool['category'] ?? '';
    final dayPrice = tool['day_price'] ?? 0;
    // /boxes/:id/tools отдаёт статус ячейки плоским полем `status`
    final available = (tool['status'] ?? tool['cell_status'] ?? tool['cells']?['status'] ?? 'free') == 'free';

    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => ToolDetailScreen(toolId: tool['id'].toString()),
      )),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.build, color: AppTheme.textHint)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('$brand \u2022 $category', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              Text('$dayPrice \u0441\u045e\u043c/\u0434\u0435\u043d\u044c',
                style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: available ? const Color(0xFFE6F7EE) : const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(999)),
                child: Text(available ? '\u0421\u0432\u043e\u0431\u043e\u0434\u0435\u043d' : '\u0417\u0430\u043d\u044f\u0442',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: available ? AppTheme.success : AppTheme.error)),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
