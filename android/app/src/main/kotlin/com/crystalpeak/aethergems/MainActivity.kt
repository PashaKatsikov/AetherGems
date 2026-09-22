package com.crystalpeak.aethergems

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val chooseChannel = "gemwell/choose"
    private val stampChannel = "gemwell/stamp"
    private val chestChannel = "gemwell/chest"
    private val liftChannel = "gemwell/lift"
    private val chooseRequest = 0x71C4
    private var pendingResult: MethodChannel.Result? = null
    private var chestPrefs: SharedPreferences? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        seatKeyboard()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        seatKeyboard()
    }

    // The window holds still for the keyboard. The IME height still arrives
    // as an inset, and the court page seats its own field instead of the
    // WebView being resized underneath it. Below API 30 the manifest's
    // adjustResize stays in charge, which is where the engine reports the
    // keyboard inset on those releases.
    private fun seatKeyboard() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val bridge = LiftBridge(this)
        MethodChannel(messenger, liftChannel).setMethodCallHandler { call, result ->
            if (call.method == "notch") {
                result.success(bridge.notch())
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, chooseChannel).setMethodCallHandler { call, result ->
            if (call.method == "choose") {
                val many = call.argument<Boolean>("many") ?: false
                val kinds = call.argument<List<String>>("kinds") ?: emptyList()
                openChooser(many, kinds, result)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, stampChannel).setMethodCallHandler { call, result ->
            if (call.method == "stamp") {
                result.success(
                    mapOf(
                        "os" to (Build.VERSION.RELEASE ?: ""),
                        "maker" to (Build.BRAND ?: ""),
                        "unit" to (Build.MODEL ?: ""),
                        "label" to (Build.DISPLAY ?: ""),
                    ),
                )
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, chestChannel).setMethodCallHandler { call, result ->
            val prefs = openChest()
            if (prefs == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            val key = call.argument<String>("key")
            if (key == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "take" -> result.success(prefs.getString(key, null))
                "keep" -> {
                    val value = call.argument<String>("value") ?: ""
                    prefs.edit().putString(key, value).apply()
                    result.success(null)
                }
                "drop" -> {
                    prefs.edit().remove(key).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openChest(): SharedPreferences? {
        chestPrefs?.let { return it }
        return try {
            val master = MasterKey.Builder(applicationContext, "k3r_ring")
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = EncryptedSharedPreferences.create(
                applicationContext,
                "k3r_chest_b",
                master,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
            chestPrefs = prefs
            prefs
        } catch (_: Exception) {
            null
        }
    }

    private fun openChooser(
        many: Boolean,
        kinds: List<String>,
        result: MethodChannel.Result,
    ) {
        pendingResult?.success(emptyList<String>())
        pendingResult = result

        val valid = kinds.filter { it.contains("/") }
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, many)
            when {
                valid.isEmpty() -> type = "*/*"
                valid.size == 1 -> type = valid[0]
                else -> {
                    type = "*/*"
                    putExtra(Intent.EXTRA_MIME_TYPES, valid.toTypedArray())
                }
            }
        }

        try {
            startActivityForResult(Intent.createChooser(intent, null), chooseRequest)
        } catch (_: Exception) {
            pendingResult = null
            result.success(emptyList<String>())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != chooseRequest) return

        val result = pendingResult
        pendingResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        val uris = ArrayList<String>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(i).uri.toString())
            }
        } else {
            data.data?.let { uris.add(it.toString()) }
        }
        result.success(uris)
    }
}
