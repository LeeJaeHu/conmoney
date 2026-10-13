package com.leejaehu.conmoney

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "conmoney/notifications")
            .setMethodCallHandler { call, result ->
                val store = RawNotificationStore.get(this)
                when (call.method) {
                    "isPermissionGranted" -> result.success(isListenerEnabled())
                    "openPermissionSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "fetchRaw" -> {
                        val afterId = (call.argument<Number>("afterId") ?: 0).toLong()
                        val limit = call.argument<Int>("limit") ?: 500
                        result.success(store.fetchSince(afterId, limit))
                    }
                    "seenPackages" -> result.success(store.seenPackages())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        val me = ComponentName(this, PaymentNotificationListener::class.java).flattenToString()
        return enabled.split(":").any { it == me }
    }
}
