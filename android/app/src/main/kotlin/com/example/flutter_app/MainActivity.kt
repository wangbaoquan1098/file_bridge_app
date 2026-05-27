package com.example.flutter_app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "file_bridge/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getStagingDirectory" -> result.success(stagingDirectory().absolutePath)
                    "publishDownload" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                            ?: throw IllegalArgumentException("sourcePath is required")
                        val fileName = call.argument<String>("fileName") ?: "download"
                        val mimeType = call.argument<String>("mimeType")
                            ?: "application/octet-stream"

                        result.success(publishDownload(sourcePath, fileName, mimeType))
                    }
                    "openFile" -> {
                        val uri = call.argument<String>("uri")
                            ?: throw IllegalArgumentException("uri is required")
                        openUri(uri)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("download_error", error.message, null)
            }
        }
    }

    private fun stagingDirectory(): File {
        val baseDirectory =
            getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        val directory = File(baseDirectory, "FileBridge")

        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Unable to create download directory")
        }

        return directory
    }

    private fun publishDownload(
        sourcePath: String,
        fileName: String,
        mimeType: String,
    ): Map<String, String?> {
        val source = File(sourcePath)
        if (!source.exists()) {
            throw IOException("Downloaded file does not exist")
        }

        val safeFileName = File(fileName).name.ifBlank { "download" }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            publishWithMediaStore(source, safeFileName, mimeType)
        } else {
            publishWithPublicDirectory(source, safeFileName)
        }
    }

    private fun publishWithMediaStore(
        source: File,
        fileName: String,
        mimeType: String,
    ): Map<String, String?> {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/FileBridge",
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Unable to create download entry")

        try {
            contentResolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input ->
                    input.copyTo(output)
                }
            } ?: throw IOException("Unable to open download entry")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            source.delete()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }

        val publicPath = File(
            File(
                Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS,
                ),
                "FileBridge",
            ),
            fileName,
        ).absolutePath

        return mapOf(
            "path" to publicPath,
            "openUri" to uri.toString(),
        )
    }

    private fun publishWithPublicDirectory(
        source: File,
        fileName: String,
    ): Map<String, String?> {
        val directory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "FileBridge",
        )
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Unable to create public download directory")
        }

        val target = File(directory, fileName)
        FileInputStream(source).use { input ->
            FileOutputStream(target).use { output ->
                input.copyTo(output)
            }
        }
        source.delete()

        return mapOf(
            "path" to target.absolutePath,
            "openUri" to null,
        )
    }

    private fun openUri(uriValue: String) {
        val uri = Uri.parse(uriValue)
        val mimeType = contentResolver.getType(uri) ?: "*/*"
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(Intent.createChooser(intent, "打开文件"))
    }
}
