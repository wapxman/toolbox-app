import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
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
      appBar: AppBar(title: const Text('Поиск')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Дрель, перфоратор, болгарка...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() { _results = []; _searched = false; });
                      },
                    )
                  : null,
              ),
              onSubmitted: _search,
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_searched
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 48, color: AppTheme.textHint),
                      const SizedBox(height: 8),
                      Text('Введите название инструмента',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ))
                : _results.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
                        const SizedBox(height: 8),
                        Text('Ничего не найдено',
                          style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Попробуйте другой запрос',
                          style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                      ],
                    ))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final tool = _results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppTheme.borderLight),
                          ),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.build, color: AppTheme.textHint, size: 20),
                          ),
                          title: Text(tool['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('${tool['brand'] ?? ''} • ${tool['day_price'] ?? 0} сўм/день',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: Icon(Icons.chevron_right, color: AppTheme.textHint),
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => ToolDetailScreen(toolId: tool['id'].toString()),
                          )),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
