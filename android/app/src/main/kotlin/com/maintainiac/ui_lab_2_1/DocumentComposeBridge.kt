package com.maintainiac.ui_lab_2_1

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

/** Opens a user-controlled composer. It never sends a document itself. */
class DocumentComposeBridge(private val activity: Activity) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "maintainiac/document_compose").setMethodCallHandler { call, result ->
            if (call.method != "compose") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val recipient = call.argument<String>("recipient")?.trim().orEmpty()
            val method = call.argument<String>("method")
            if (bytes == null || bytes.size < 5 || String(bytes.take(5).toByteArray()) != "%PDF-" ||
                recipient.isEmpty() || (method != "email" && method != "textMessage")) {
                result.error("invalid_document", "A PDF and recipient are required.", null)
                return@setMethodCallHandler
            }
            try {
                val directory = File(activity.cacheDir, "customer_documents/${UUID.randomUUID()}")
                directory.mkdirs()
                val name = (call.argument<String>("name") ?: "Estimate.pdf").replace(Regex("[^a-zA-Z0-9 _.()-]"), "-")
                val file = File(directory, name)
                file.writeBytes(bytes)
                val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.customer_documents", file)
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "application/pdf"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject"))
                    putExtra(Intent.EXTRA_TEXT, call.argument<String>("text"))
                    clipData = ClipData.newUri(activity.contentResolver, "Customer PDF", uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    if (method == "email") {
                        putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                    } else {
                        putExtra("address", recipient)
                        putExtra("sms_body", call.argument<String>("text"))

                    }
                }
                // Discover the requested category separately: SENDTO identifies email/
                // messaging apps, while SEND preserves a real PDF attachment.
                val category = Intent(Intent.ACTION_SENDTO, Uri.parse(if (method == "email") "mailto:" else "smsto:"))
                val packages = activity.packageManager.queryIntentActivities(category, PackageManager.MATCH_DEFAULT_ONLY)
                    .map { it.activityInfo.packageName }.toSet()
                val targets = activity.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    .filter { it.activityInfo.packageName in packages }
                    .map { Intent(intent).setClassName(it.activityInfo.packageName, it.activityInfo.name) }
                if (targets.isEmpty()) {
                    result.error("composer_unavailable", if (method == "email")
                        "No email app that accepts PDFs is available. Install an email app, or use Share from this device."
                        else "No messaging app that accepts PDFs is available. Use email or Share from this device. Ordinary SMS cannot carry a PDF.", null)
                    return@setMethodCallHandler
                }
                val chooser = Intent.createChooser(targets.first(), if (method == "email") "Email estimate" else "Text estimate")
                if (targets.size > 1) chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, targets.drop(1).toTypedArray())
                activity.startActivity(chooser)
                // The composer owns the next step; launching it does not prove sending.
                result.success("unconfirmed")
            } catch (error: Exception) {
                result.error("composer_unavailable", "The composer could not open. Try Share PDF or save the PDF and attach it manually.", null)
            }
        }
    }
}
