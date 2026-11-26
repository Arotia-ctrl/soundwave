package com.ares.soundwave

import android.content.ContentUris
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {

    // Un seul fil, en priorité basse : la lecture audio passe toujours avant l'analyse
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
            runnable.run()
        }.apply { name = "soundwave-analyzer" }
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundwave/analyzer")
            .setMethodCallHandler { call, result ->
                if (call.method != "analyze") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val id = call.argument<Number>("id")?.toLong()
                if (id == null) {
                    result.error("bad_args", "id manquant", null)
                    return@setMethodCallHandler
                }
                executor.execute {
                    try {
                        val uri = ContentUris.withAppendedId(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id
                        )
                        val features = AudioAnalyzer.analyze(applicationContext, uri)
                        mainHandler.post { result.success(features) }
                    } catch (e: Throwable) {
                        mainHandler.post { result.error("analysis_failed", e.message, null) }
                    }
                }
            }
    }
}