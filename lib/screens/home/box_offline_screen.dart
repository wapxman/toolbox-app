import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BoxOfflineScreen extends StatelessWidget {
  final String boxName;
  final String address;

  const BoxOfflineScreen({
    super.key,
    required this.boxName,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(boxName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off, size: 40, color: AppTheme.error),
              ),
              const SizedBox(height: 24),
              const Text(
                'Бокс оффлайн',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'К сожалению, $boxName сейчас\nнедоступен. Попробуйте позже\nили выберите другой бокс.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(address,
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Выбрать другой бокс'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
