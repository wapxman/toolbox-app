package uz.taketool.app

import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    // MapKit настраивается один раз на процесс: setLocale/setApiKey нельзя звать после
    // инициализации карты, иначе AssertionError. А configureFlutterEngine выполняется при
    // каждом создании Activity, в том числе когда система пересоздала её при возврате из фона.
    private companion object {
        var mapKitConfigured = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        if (!mapKitConfigured) {
            MapKitFactory.setLocale("ru_RU")
            MapKitFactory.setApiKey("5270c38f-0974-4c61-b17e-757275f3937e")
            mapKitConfigured = true
        }
        super.configureFlutterEngine(flutterEngine)
    }
}
