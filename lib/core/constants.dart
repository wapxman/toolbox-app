class ApiConfig {
  static const String baseUrl = 'https://toolbox-backend-eight.vercel.app/api';
  /// Уходит в заголовке X-App-Version — попадает в журнал согласий с офертой.
  /// ⚠️ Держать в соответствии с version в pubspec.yaml: иначе в журнале
  /// окажется версия, которой у пользователя нет (так было с 1.1.2+11 при 1.1.3+12).
  static const String appVersion = '1.1.4+13';
  static const Duration timeout = Duration(seconds: 15);
}

/// Публичные страницы (требования Google Play / App Store)
class LegalLinks {
  static const String site = 'https://taketool.uz';
  static const String privacy = 'https://www.taketool.uz/privacy.html';
  static const String terms = 'https://www.taketool.uz/terms.html';
  static const String deleteAccount = 'https://www.taketool.uz/delete-account.html';
  static const String supportEmail = 'support@taketool.uz';
  static const String supportPhone = '+998 93 523 60 60';
}

/// Переключатели поведения приложения.
class AppFlags {
  /// true — регистрация по телефону на старте, каталог только после входа.
  /// false — гостевой каталог, вход просим при оформлении аренды.
  ///
  /// 21.09.2026 владелец включил регистрацию на старте для Android.
  /// 08.10.2026 владелец отменил это решение и велел открыть каталог гостям
  /// на обеих платформах. Причина — цифры воронки за 28 дней:
  /// 3 650 человек открыли карточку в Play → 38 установили (1 %, норма 20–30 %)
  /// → 1 запустил приложение. Люди упирались в «Введите номер телефона»,
  /// не увидев ни одного инструмента.
  ///
  /// На iOS иначе и нельзя: App Store отклонял сборку 1.0.5 (01.09.2026) по
  /// Guideline 5.1.1(v) — «Registration can only be required for account-based
  /// features like adding to cart or checking out».
  static bool get requireLoginAtStart => false;
}

class AppConstants {
  // Фолбэк, если у инструмента не пришла цена с бэкенда
  static const int basePricePerDay = 80000; // сум
  static const double discount3Days = 0.20;
  static const double discount7Days = 0.35;

  // Цена считается ОТ КОНКРЕТНОГО инструмента (у всех разные цены/день)
  static int priceForDays(int days, int pricePerDay) {
    if (days >= 7) return (days * pricePerDay * (1 - discount7Days)).round();
    if (days >= 3) return (days * pricePerDay * (1 - discount3Days)).round();
    return days * pricePerDay;
  }

  static String formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} сўм';
  }

  static String daysWord(int d) {
    if (d == 1) return 'день';
    if (d >= 2 && d <= 4) return 'дня';
    return 'дней';
  }
}
