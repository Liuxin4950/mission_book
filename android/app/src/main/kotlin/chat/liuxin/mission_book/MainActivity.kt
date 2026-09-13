package chat.liuxin.mission_book

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

/**
 * Android 只实现 Mission Book 当前需要的 openFile。
 *
 * 系统 ACTION_OPEN_DOCUMENT 负责授权；选中的外部 Uri 会先复制到应用 cache，
 * Flutter 随后再复制到正式的 Evidence 私有目录。这样既不申请存储权限，也不
 * 长期依赖 ContentProvider 的临时授权。
 */
class MainActivity : FlutterActivity() {
    private var pendingFileResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fileSelectorCacheRoot().deleteRecursively()
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_SELECTOR_CHANNEL,
        ).setMethodCallHandler(::handleFileSelectorCall)
    }

    private fun handleFileSelectorCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "openFile") {
            result.notImplemented()
            return
        }
        if (pendingFileResult != null) {
            result.error("selection_in_progress", "已有文件选择窗口正在打开。", null)
            return
        }

        val mimeTypes = extractMimeTypes(call)
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimeTypes.size == 1) mimeTypes.single() else "*/*"
            if (mimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
        }
        pendingFileResult = result
        try {
            startActivityForResult(intent, OPEN_FILE_REQUEST_CODE)
        } catch (error: Exception) {
            pendingFileResult = null
            result.error("open_file_failed", error.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != OPEN_FILE_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingFileResult ?: return
        pendingFileResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.error("empty_selection", "系统没有返回可读取的文件。", null)
            return
        }
        try {
            result.success(listOf(copySelectionToCache(uri).absolutePath))
        } catch (error: Exception) {
            result.error("copy_selection_failed", error.message, null)
        }
    }

    private fun copySelectionToCache(uri: Uri): File {
        val rawName = queryDisplayName(uri) ?: "attachment"
        // ContentProvider 的文件名属于不可信输入：去掉路径片段与控制字符。
        val safeName = rawName
            .replace('\\', '/')
            .substringAfterLast('/')
            .replace(Regex("[\\u0000-\\u001F\\u007F]"), "_")
            .take(180)
            .ifBlank { "attachment" }
        val root = fileSelectorCacheRoot()
        root.deleteRecursively()
        val targetDirectory = File(root, UUID.randomUUID().toString())
        check(targetDirectory.mkdirs() || targetDirectory.isDirectory) {
            "无法创建文件选择缓存目录。"
        }
        val target = File(targetDirectory, safeName)
        contentResolver.openInputStream(uri).use { input ->
            checkNotNull(input) { "无法读取所选文件。" }
            target.outputStream().use { output -> input.copyTo(output) }
        }
        return target
    }

    private fun queryDisplayName(uri: Uri): String? {
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index < 0) null else cursor.getString(index)
        }
    }

    private fun extractMimeTypes(call: MethodCall): List<String> {
        val groups = call.argument<List<*>>("acceptedTypeGroups") ?: return emptyList()
        return groups.flatMap { group ->
            val map = group as? Map<*, *> ?: return@flatMap emptyList()
            val values = map["mimeTypes"] as? List<*> ?: return@flatMap emptyList()
            values.filterIsInstance<String>()
        }.distinct()
    }

    private fun fileSelectorCacheRoot(): File =
        File(cacheDir, "mission_book_file_selector")

    private companion object {
        const val FILE_SELECTOR_CHANNEL = "plugins.flutter.io/file_selector"
        const val OPEN_FILE_REQUEST_CODE = 43021
    }
}
