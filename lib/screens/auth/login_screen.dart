import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(4, (_) => FocusNode());
  bool _codeSent = false;

  void _sendCode() {
    if (_phoneController.text.length >= 9) {
      setState(() => _codeSent = true);
      _codeFocusNodes[0].requestFocus();
    }
  }

  void _verifyCode() {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _codeControllers) c.dispose();
    for (final f in _codeFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вход',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Введите номер телефона',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Text(
                    '+998',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(hintText: '90 123 45 67'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _sendCode,
              child: const Text('Получить код'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 28),
              Text(
                'Введите код из SMS',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _codeControllers[i],
                      focusNode: _codeFocusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(counterText: ''),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) {
                          _codeFocusNodes[i + 1].requestFocus();
                        }
                        if (i == 3 && v.isNotEmpty) _verifyCode();
                      },
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, fontFamily: 'SFPro'),
                    children: [
                      TextSpan(
                        text: 'Нет аккаунта? ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextSpan(
                        text: 'Зарегистрироваться',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
