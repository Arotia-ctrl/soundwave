package com.ares.soundwave

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.MediaStore
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import android.app.NotificationManager
import android.content.Context

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val PERMISSION_REQUEST = 4242
    }

    // Analyse : un seul fil, en priorité basse (la lecture passe toujours avant)
    private val analyzerExecutor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread {
            Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
            runnable.run()
        }.apply { name = "soundwave-analyzer" }
    }

    // Bibliothèque et pochettes
    private val libraryExecutor: ExecutorService = Executors.newFixedThreadPool(2)

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermission: MethodChannel.Result? = null

    private val mediaPermission: String
        get() = if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ---- Analyse audio ----
        MethodChannel(messenger, "soundwave/analyzer").setMethodCallHandler { call, result ->
            if (call.method != "analyze") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val id = call.argument<Number>("id")?.toLong()
            if (id == null) {
                result.error("bad_args", "id manquant", null)
                return@setMethodCallHandler
            }
            runAsync(result, analyzerExecutor) {
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                AudioAnalyzer.analyze(applicationContext, uri)
            }
        }

        // ---- Bibliothèque, pochettes, permissions ----
        MethodChannel(messenger, "soundwave/library").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(granted(mediaPermission))
                "requestPermission" -> requestPermission(result)
                "openSettings" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null)
                        )
                    )
                    result.success(null)
                }
                "queryTracks" -> runAsync(result, libraryExecutor) {
                    MediaLibrary.queryTracks(applicationContext)
                }
                "artwork" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    val size = call.argument<Number>("size")?.toInt() ?: 192
                    if (id == null) {
                        result.error("bad_args", "id manquant", null)
                    } else {
                        runAsync(result, libraryExecutor) {
                            MediaLibrary.artwork(applicationContext, id, size)
                        }
                    }
                }
                "notificationsEnabled" -> result.success(notificationsEnabled())
                "openNotificationSettings" -> {
                    val intent = if (Build.VERSION.SDK_INT >= 26) {
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    } else {
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null)
                        )
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun runAsync(
        result: MethodChannel.Result,
        executor: ExecutorService,
        block: () -> Any?,
    ) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Throwable) {
                mainHandler.post { result.error("native_error", e.message, null) }
            }
        }
    }

    private fun notificationsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < 24) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.areNotificationsEnabled()
    }

    // ---- Permissions ----

    private fun requestPermission(result: MethodChannel.Result) {
        val needed = mutableListOf<String>()
        if (!granted(mediaPermission)) needed.add(mediaPermission)
        if (Build.VERSION.SDK_INT >= 33 && !granted(Manifest.permission.POST_NOTIFICATIONS)) {
            needed.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (needed.isEmpty()) {
            result.success("granted")
            return
        }
        if (pendingPermission != null) {
            result.error("busy", "Une demande est déjà en cours", null)
            return
        }
        pendingPermission = result
        requestPermissions(needed.toTypedArray(), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        val pending = pendingPermission ?: return
        pendingPermission = null

        val status = when {
            granted(mediaPermission) -> "granted"
            !shouldShowRequestPermissionRationale(mediaPermission) -> "blocked"
            else -> "denied"
        }
        pending.success(status)
    }
}