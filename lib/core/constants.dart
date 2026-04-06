class ApiConfig {
  static const String baseUrl = 'https://toolbox-backend-eight.vercel.app/api';
  static const Duration timeout = Duration(seconds: 15);
}

class AppConstants {
  static const int basePricePerDay = 80000; // сум
  static const double discount3Days = 0.20;
  static const double discount7Days = 0.35;

  static int priceForDays(int days) {
    if (days >= 7) return (days * basePricePerDay * (1 - discount7Days)).round();
    if (days >= 3) return (days * basePricePerDay * (1 - discount3Days)).round();
    return days * basePricePerDay;
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
