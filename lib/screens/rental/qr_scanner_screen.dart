import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../home/box_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _api = ApiService();
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handling = false;
  bool _torchOn = false;

  // Достаём UUID бокса из содержимого QR: сырой UUID, ссылка,
  // deep-link toolbox://box/<id> — берём первое, что похоже на UUID.
  String? _extractBoxId(String raw) {
    final m = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(raw);
    return m?.group(0);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    final boxId = _extractBoxId(code);
    if (boxId == null) {
      _toast('QR не распознан. Наведите на код с дверцы бокса.');
      return;
    }

    setState(() => _handling = true);
    await _controller.stop();
    try {
      final box = await _api.getBox(boxId);
      if (!mounted) return;
      final online = (box['status'] ?? 'online') == 'online';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BoxDetailScreen(
            boxId: box['id'].toString(),
            boxName: box['name'] ?? 'Бокс',
            address: box['address'] ?? '',
            online: online,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _handling = false);
      await _controller.start();
      _toast(e is ApiException ? e.message : 'Бокс не найден');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography, color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Нет доступа к камере.\nРазрешите камеру в настройках приложения.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Рамка прицела
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary, width: 3),
              ),
            ),
          ),

          if (_handling)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Подписи
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              children: [
                const Text(
                  'Наведите камеру на QR-код',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'QR-код находится на дверце бокса',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),

          // Верхняя панель: закрыть + фонарик
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(Icons.close, () => Navigator.pop(context)),
                  _roundButton(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
