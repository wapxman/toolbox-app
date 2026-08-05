import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ключ Яндекс MapKit — тот же, что в Android (MainActivity.kt).
    // Инициализация обязана быть ДО регистрации плагинов.
    YMKMapKit.setLocale("ru_RU")
    YMKMapKit.setApiKey("5270c38f-0974-4c61-b17e-757275f3937e")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
