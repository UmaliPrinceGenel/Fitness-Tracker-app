package com.example.rockies_fitness_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "rockies_fitness/asset_copy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copyAssetToFile" -> {
                        val assetKey = call.argument<String>("assetKey")
                        val destPath = call.argument<String>("destPath")
                        if (assetKey == null || destPath == null) {
                            result.error("INVALID_ARGS", "assetKey and destPath are required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                copyAssetToFile(assetKey, destPath)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("COPY_FAILED", e.message, null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun copyAssetToFile(assetKey: String, destPath: String) {
        val destFile = File(destPath)
        destFile.parentFile?.mkdirs()

        // Stream-copy in 64KB chunks to avoid loading the entire file into memory.
        val assetManager = assets
        assetManager.open("flutter_assets/$assetKey").use { input ->
            FileOutputStream(destFile).use { output ->
                val buffer = ByteArray(65536)
                var bytesRead: Int
                while (input.read(buffer).also { bytesRead = it } != -1) {
                    output.write(buffer, 0, bytesRead)
                }
                output.flush()
            }
        }
    }
}