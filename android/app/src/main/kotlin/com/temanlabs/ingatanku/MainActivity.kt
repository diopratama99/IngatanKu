package com.temanlabs.ingatanku

import android.os.Build
import android.os.Bundle
import android.view.View
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Once a keyboard is used (a hardware one, a Chromebook's), Android
        // outlines the focused view — for Flutter that's the whole screen,
        // in bright green, until the app is left. Flutter shows focus
        // itself, so the system's outline is off.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            findViewById<View>(FLUTTER_VIEW_ID)?.defaultFocusHighlightEnabled = false
        }
    }
}
