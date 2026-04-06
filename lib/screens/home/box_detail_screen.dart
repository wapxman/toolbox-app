import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'tool_detail_screen.dart';

class BoxDetailScreen extends StatelessWidget {
  final String boxName;
  final String address;
  final bool online;

  const BoxDetailScreen({
    super.key,
    required this.boxName,
    required this.address,
    this.online = true,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool('Дрель Bosch GSB 13 RE', 'Дрели', 80000, true),
      _Tool('Шуруповёрт Makita DF331D', 'Шуруповёрты', 80000, true),
      _Tool('Болгарка DeWalt DWE4057', 'Болгарки', 80000, false),
      _Tool('Перфоратор Bosch GBH 2-26', 'Перфораторы', 80000, true),
      _Tool('Лобзик Makita 4329', 'Пилы', 80000, true),
      _Tool('Шлифмашина Bosch GEX 125', 'Шлифовка', 80000, false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(boxName),
      ),
      body: Column(
        children: [
          // Box info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: online ? AppTheme.primary : AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      online ? 'Онлайн' : 'Оффлайн',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: online ? AppTheme.primary : AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '24/7',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tools.where((t) => t.available).length} из ${tools.length} инструментов свободно',
                  style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
              ],
            ),
          ),
          // Tools list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Инструменты',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final tool = tools[i];
                return GestureDetector(
                  onTap: tool.available
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ToolDetailScreen(
                                toolName: tool.name,
                                category: tool.category,
                                pricePerDay: tool.price,
                                boxName: boxName,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.borderLight),
                      color: tool.available
                          ? Colors.white
                          : const Color(0xFFFAFAFA),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            Icons.build,
                            color: tool.available
                                ? AppTheme.textSecondary
                                : AppTheme.textHint,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: tool.available
                                      ? AppTheme.textPrimary
                                      : AppTheme.textHint,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatPrice(tool.price)}/день',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: tool.available
                                ? const Color(0xFFE6F7EE)
                                : const Color(0xFFFDE8E8),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            tool.available ? 'Свободен' : 'Занят',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tool.available
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ),
                        if (tool.available) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              size: 18, color: AppTheme.textHint),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} сўм';
  }
}

class _Tool {
  final String name;
  final String category;
  final int price;
  final bool available;
  _Tool(this.name, this.category, this.price, this.available);
}
