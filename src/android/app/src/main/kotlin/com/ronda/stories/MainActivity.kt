package com.ronda.stories

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ronda.stories/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTtsSettings" -> {
                        // Apre direttamente la schermata Text-to-speech
                        // nelle impostazioni di sistema Android
                        val intent = Intent(Settings.ACTION_VOICE_INPUT_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        // Fallback a impostazioni accessibilità generali
                        // se TTS non è disponibile come schermata separata
                        try {
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            try {
                                val fallback = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(fallback)
                                result.success(null)
                            } catch (e2: Exception) {
                                result.error("UNAVAILABLE", "Impossibile aprire le impostazioni", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
