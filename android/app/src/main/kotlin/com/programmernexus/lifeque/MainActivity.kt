package com.programmernexus.lifeque

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
