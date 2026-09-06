package com.programmernexus.lifeque

import android.app.LocaleManager
import android.content.Intent
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /**
     * Lets Flutter hand the platform the language the user picked in the app.
     *
     * Android resource qualifiers follow the *system* language, so a phone set
     * to English would show English widget-picker labels and English widget
     * placeholders even with LifeQue set to Bangla. Setting a per-app locale
     * (API 33+) makes `values-bn` apply to this app's resources regardless of
     * what the rest of the phone is doing.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCALE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "setAppLocale") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val tag = call.argument<String>("languageTag")
                if (tag.isNullOrBlank()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    getSystemService(LocaleManager::class.java)
                        ?.applicationLocales = LocaleList.forLanguageTags(tag)
                    result.success(true)
                } else {
                    // Below 33 there is no per-app locale; the widget picker
                    // keeps following the system language, which is the best
                    // the platform offers.
                    result.success(false)
                }
            }
    }

    companion object {
        private const val LOCALE_CHANNEL = "com.programmernexus.lifeque/locale"
    }
    /**
     * Keeps [getIntent] pointing at the intent that actually brought the
     * activity forward.
     *
     * Tapping a home-screen widget starts the activity with the launcher's own
     * `android.intent.action.MAIN`, and our widget intent — carrying
     * `lifeque://prayer-times` — is delivered a moment later through
     * `onNewIntent`. Without this, `getIntent()` still returns MAIN, so
     * `HomeWidget.initiallyLaunchedFromHomeWidget()` reports null and the tap
     * is indistinguishable from opening the app from the home screen.
     */
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}
