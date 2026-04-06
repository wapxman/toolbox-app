import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../home/main_screen.dart';

class UnlockScreen extends StatefulWidget {
  final String toolName;

  const UnlockScreen({super.key, required this.toolName});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with TickerProviderStateMixin {
  bool _unlocking = true;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    // Simulate unlocking
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _unlocking = false; _unlocked = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _unlocking ? _buildUnlocking() : _buildUnlocked(),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlocking() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Открываем ячейку...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Подождите, идёт связь с боксом',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUnlocked() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_open, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 28),
        const Text(
          'Ячейка открыта!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Заберите ${widget.toolName}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF7E6),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            'Ячейка закроется через 30 сек',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.warning,
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (_) => false,
            );
          },
          child: const Text('Готово'),
        ),
      ],
    );
  }
}
