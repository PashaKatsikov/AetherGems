package com.crystalpeak.aethergems

import android.app.Activity
import androidx.core.view.ViewCompat

// Reads the hardware cutout for the court WebView. The window is laid out
// edge to edge and the page is handed a zeroed MediaQuery, so the only inset
// the Dart side still has to honour is the notch itself.
class LiftBridge(private val activity: Activity) {

    fun notch(): Map<String, Int> {
        val cutout = ViewCompat
            .getRootWindowInsets(activity.window.decorView)
            ?.displayCutout

        return mapOf(
            "left" to (cutout?.safeInsetLeft ?: 0),
            "top" to (cutout?.safeInsetTop ?: 0),
            "right" to (cutout?.safeInsetRight ?: 0),
            "bottom" to (cutout?.safeInsetBottom ?: 0),
        )
    }
}
