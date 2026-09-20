import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/delivery_form.dart';
import 'payment_screen.dart';

/// Вызов курьера за арендованным инструментом (платно, тариф доставки).
class CourierReturnScreen extends StatefulWidget {
  final String rentalId;
  final String toolName;
  const CourierReturnScreen({super.key, required this.rentalId, required this.toolName});

  @override
  State<CourierReturnScreen> createState() => _CourierReturnScreenState();
}

class _CourierReturnScreenState extends State<CourierReturnScreen> {
  final _api = ApiService();
  final _delivery = DeliveryFormController();
  List<dynamic> _slots = [];
  int _fee = 50000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getDeliverySettings(),
        _api.getMe().catchError((_) => <String, dynamic>{}),
      ]);
      final s = results[0];
      final me = results[1];
      final phone = (me['user']?['phone'] ?? me['phone'] ?? '').toString();
      if (phone.isNotEmpty) _delivery.phone.text = phone;
      if (mounted) setState(() { _slots = s['slots'] ?? []; _fee = (s['fee'] ?? 50000) as int; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _delivery.dispose();
    super.dispose();
  }

  void _next() {
    final err = _delivery.validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentScreen(
        toolId: '',
        toolName: widget.toolName,
        kind: 'courier_return',
        fulfillment: 'delivery',
        delivery: _delivery.toJson(),
        slotLabel: _delivery.slotLabel,
        deliveryFee: _fee,
        totalPrice: _fee,
        rentalId: widget.rentalId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вызвать курьера')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  child: Text(
                    'Курьер приедет по вашему адресу и заберёт «${widget.toolName}». '
                    'Аренда завершится в момент передачи. Выезд стоит ${AppConstants.formatPrice(_fee)}.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Откуда забрать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                DeliveryForm(controller: _delivery, slots: _slots, slotsTitle: 'Когда забрать'),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _next, child: Text('К оплате ${AppConstants.formatPrice(_fee)}')),
              ]),
            ),
    );
  }
}
