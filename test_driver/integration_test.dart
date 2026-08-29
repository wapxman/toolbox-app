import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Снимки для App Store.
///
/// Снимаем именно слой Flutter: карта Яндекса рендерится через текстуру
/// и в кадр попадает. Заход через `xcrun simctl io screenshot` не годится —
/// обратные вызовы драйвера приходят уже после завершения теста, и все
/// снимки получаются одинаковыми, с последним состоянием экрана.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final dir = Directory('build/ios_shots')..createSync(recursive: true);
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
