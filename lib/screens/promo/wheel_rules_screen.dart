// Правила акции «Колесо Фортуны».
//
// Экран обязателен, и не ради красоты:
//  • Apple App Store Review Guidelines 5.3.2 — официальные правила розыгрыша
//    должны быть представлены В ПРИЛОЖЕНИИ, и там же сказано, что Apple не
//    является спонсором акции и не имеет к ней отношения;
//  • Google Play, раздел Gamified Loyalty Programs — правила внутри
//    приложения, фиксированное число победителей, дедлайн участия и дата
//    выдачи приза.
//
// Числа берём с сервера, а не из текста: правила и поведение должны совпадать.
// Если владелец поменяет срок или число победителей в админке, экран скажет
// новое — расхождение между обещанием и кодом здесь дороже всего.
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WheelRulesScreen extends StatelessWidget {
  final Map<String, dynamic> rules;
  final List<Map<String, dynamic>> prizes;
  const WheelRulesScreen({super.key, required this.rules, this.prizes = const []});

  int get _winnersLimit => (rules['winners_limit'] ?? 0) as int;
  int get _winnersSoFar => (rules['winners_so_far'] ?? 0) as int;
  int get _spins => (rules['spins_per_user'] ?? 1) as int;
  int get _expires => (rules['expires_days'] ?? 30) as int;
  int get _maxPct => (rules['max_pay_pct'] ?? 50) as int;

  String get _endsAt {
    final raw = rules['ends_at']?.toString();
    if (raw == null || raw.isEmpty) return 'до отмены организатором';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} года';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Правила акции')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          _h('Организатор'),
          _p('Акцию проводит Taketool — сервис аренды инструмента. '
              'Организатор несёт полную ответственность за проведение акции '
              'и выдачу призов.'),

          _h('Кто участвует'),
          _p('Любой пользователь приложения Taketool. Участие бесплатное: '
              'покупка или аренда не требуется и не влияет на шанс выигрыша.'),

          _h('Сколько попыток'),
          _p(_spins == 1
              ? 'Одна попытка на человека за всю акцию. Попытка привязана к '
                'номеру телефона: повторная установка приложения новой попытки '
                'не даёт.'
              : 'Попыток на человека: $_spins. Они привязаны к номеру телефона.'),

          _h('Сколько победителей'),
          _p(_winnersLimit > 0
              ? 'Победителей — $_winnersLimit. Когда все призы разыграны, '
                'акция закрывается, даже если срок ещё не вышел.'
              : 'Число победителей не ограничено.'),
          if (_winnersLimit > 0) _progress(),

          _h('Срок участия'),
          _p('Акция идёт по $_endsAt включительно. После этой даты прокрутка '
              'становится недоступна.'),

          _h('Когда выдаются призы'),
          _p('Денежный бонус зачисляется на бонусный счёт в приложении '
              'сразу после прокрутки — ждать не нужно. '
              'Инструменты выдаются по запросу: обратитесь в пункт выдачи '
              'Taketool или напишите в поддержку, и мы согласуем выдачу.'),

          _h('Как работает бонус'),
          _p('Бонус — это скидка на аренду, а не деньги. Его нельзя обналичить '
              'и нельзя перевести другому человеку. '
              'Бонус действует $_expires дней с момента начисления и покрывает '
              'до $_maxPct% стоимости аренды. На доставку не распространяется.'),

          if (prizes.isNotEmpty) ...[
            _h('Призовой фонд'),
            ...prizes.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('•  ', style: TextStyle(color: AppTheme.textSecondary)),
                    Expanded(
                      child: Text(
                        '${p['label']} — '
                        '${p['kind'] == 'item' ? 'инструмент, выдаётся по запросу' : 'бонус на аренду'}',
                        style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.45),
                      ),
                    ),
                  ]),
                )),
          ],

          _h('Как определяется приз'),
          _p('Приз выбирает сервер в момент прокрутки, случайным образом, '
              'с заданными вероятностями. Приложение только показывает '
              'результат — повлиять на него с телефона невозможно.'),

          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.borderLight),
            ),
            // Дословное требование Apple 5.3.2.
            child: Text(
              'Apple не является спонсором акции и не имеет к ней никакого '
              'отношения. Google не является спонсором акции и не имеет к ней '
              'никакого отношения.',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    final done = _winnersLimit > 0 ? (_winnersSoFar / _winnersLimit).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done,
            minHeight: 7,
            backgroundColor: AppTheme.borderLight,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text('Разыграно $_winnersSoFar из $_winnersLimit',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
      ]),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 7),
        child: Text(t,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _p(String t) => Text(t,
      style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.5));
}
