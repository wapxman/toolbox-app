import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/tool_photo.dart';
import 'tool_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _searched = true; });
    try {
      final results = await _api.searchTools(query.trim());
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('\u041f\u043e\u0438\u0441\u043a')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '\u0414\u0440\u0435\u043b\u044c, \u043f\u0435\u0440\u0444\u043e\u0440\u0430\u0442\u043e\u0440, \u0431\u043e\u043b\u0433\u0430\u0440\u043a\u0430...',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_searched
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search, size: 48, color: AppTheme.textHint),
                  const SizedBox(height: 8),
                  Text('\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435', style: TextStyle(color: AppTheme.textSecondary)),
                ]))
              : _results.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
                    const SizedBox(height: 8),
                    Text('\u041d\u0438\u0447\u0435\u0433\u043e \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u043e', style: TextStyle(color: AppTheme.textSecondary)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tool = _results[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.borderLight)),
                        leading: ToolPhoto(url: tool['photo_url']?.toString(), width: 44, height: 44, radius: 8, iconSize: 20),
                        title: Text(tool['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('${tool['brand'] ?? ''} \u2022 ${tool['day_price'] ?? 0} \u0441\u045e\u043c/\u0434\u0435\u043d\u044c',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        trailing: Icon(Icons.chevron_right, color: AppTheme.textHint),
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => ToolDetailScreen(toolId: tool['id'].toString()))),
                      );
                    }),
        ),
      ]),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}
