package uz.toolbox.toolbox_app

import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MapKitFactory.setLocale("ru_RU")
        MapKitFactory.setApiKey("5270c38f-0974-4c61-b17e-757275f3937e")
        super.configureFlutterEngine(flutterEngine)
    }
}
