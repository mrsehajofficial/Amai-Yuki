package com.sehaj.amaiyuki

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val params = window.attributes
            // Request the highest refresh rate mode
            val modes = display?.supportedModes
            val highRefreshMode = modes?.maxByOrNull { it.refreshRate }
            if (highRefreshMode != null) {
                params.preferredDisplayModeId = highRefreshMode.modeId
                window.attributes = params
            }
        }
    }
}
