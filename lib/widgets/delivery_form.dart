import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Данные формы доставки: адрес, подъезд/этаж/кв, телефон, комментарий, интервал.
/// Используется и при заказе с доставкой, и при вызове курьера за инструментом.
class DeliveryFormController {
  final address = TextEditingController();
  final entrance = TextEditingController();
  final floor = TextEditingController();
  final apt = TextEditingController();
  final phone = TextEditingController();
  final comment = TextEditingController();
  Map<String, dynamic>? slot; // {date, start, end, label}

  void dispose() {
    for (final c in [address, entrance, floor, apt, phone, comment]) {
      c.dispose();
    }
  }

  /// Текст ошибки или null, если всё заполнено.
  String? validate() {
    if (address.text.trim().length < 5) return 'Укажите адрес доставки';
    if (phone.text.replaceAll(RegExp(r'\D'), '').length < 9) return 'Укажите телефон получателя';
    if (slot == null) return 'Выберите, когда привезти';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'address': address.text.trim(),
        'entrance': entrance.text.trim(),
        'floor': floor.text.trim(),
        'apt': apt.text.trim(),
        'phone': phone.text.trim(),
        'comment': comment.text.trim(),
        'slot': {
          'date': slot?['date'],
          'start': slot?['start'],
          'end': slot?['end'],
        },
      };

  String get slotLabel => slot?['label']?.toString() ?? '';
}

class DeliveryForm extends StatefulWidget {
  final DeliveryFormController controller;
  final List<dynamic> slots; // из /settings/delivery
  final String slotsTitle;

  const DeliveryForm({
    super.key,
    required this.controller,
    required this.slots,
    this.slotsTitle = 'Когда привезти',
  });

  @override
  State<DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<DeliveryForm> {
  DeliveryFormController get c => widget.controller;

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      );

  @override
  Widget build(BuildContext context) {
    final available = widget.slots.where((s) => s['available'] == true).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: c.address,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec('Адрес', hint: 'ул. Бабура, 45'),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: c.entrance, decoration: _dec('Подъезд'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: c.floor, decoration: _dec('Этаж'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: c.apt, decoration: _dec('Квартира'))),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: c.phone,
          keyboardType: TextInputType.phone,
          decoration: _dec('Телефон получателя', hint: '+998 90 000 00 00'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c.comment,
          decoration: _dec('Комментарий курьеру', hint: 'Код домофона, ориентир…'),
        ),
        const SizedBox(height: 18),
        Text(widget.slotsTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (available.isEmpty)
          Text('На ближайшие дни интервалов нет — попробуйте позже.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.4,
            children: available.map((s) {
              final selected = c.slot != null &&
                  c.slot!['date'] == s['date'] && c.slot!['start'] == s['start'];
              return GestureDetector(
                onTap: () => setState(() => c.slot = Map<String, dynamic>.from(s)),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFF3F3) : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    s['label']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 6),
        Text('Интервал «сегодня» доступен, если до его начала больше 2 часов.',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
      ],
    );
  }
}
