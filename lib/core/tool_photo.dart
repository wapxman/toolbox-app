import 'package:flutter/material.dart';
import 'theme.dart';

/// Фото инструмента из photo_url. При отсутствии/ошибке — иконка-заглушка.
class ToolPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;
  const ToolPhoto({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 8,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = height;
    Widget placeholder() => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(Icons.build, size: iconSize, color: AppTheme.textHint),
        );

    final u = url?.trim() ?? '';
    if (u.isEmpty) return placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: w,
        height: h,
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: Image.network(
          u,
          fit: BoxFit.contain,
          loadingBuilder: (c, child, progress) => progress == null
              ? child
              : Container(
                  color: AppTheme.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (c, e, s) => placeholder(),
        ),
      ),
    );
  }
}
