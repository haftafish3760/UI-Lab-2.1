package com.maintainiac.ui_lab_2_1

import android.content.Context
import java.io.File
import java.io.IOException
import java.security.MessageDigest

/** Validate retained receipt references before native bitmap decoding. */
internal fun verifiedReceiptGuide(context: Context, value: Map<*, *>?): String? {
    if (value == null) return null
    val path = value["path"] as? String ?: throw IOException("Missing guide path")
    val length = (value["length"] as? Number)?.toLong() ?: throw IOException("Missing guide length")
    val expected = value["sha256"] as? String ?: throw IOException("Missing guide digest")
    val file = File(path)
    val root = context.dataDir.canonicalPath + File.separator
    if (!file.isAbsolute || file.canonicalFile != file.absoluteFile ||
        !file.canonicalPath.startsWith(root) || !file.isFile ||
        length !in 1..(32L * 1024 * 1024) || file.length() != length ||
        !expected.matches(Regex("[a-f0-9]{64}"))) {
        throw IOException("Receipt guide is unavailable")
    }
    val hash = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
        val buffer = ByteArray(65536)
        var total = 0L
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            total += count
            if (total > length) throw IOException("Receipt guide changed")
            hash.update(buffer, 0, count)
        }
        if (total != length) throw IOException("Receipt guide changed")
    }
    val actual = hash.digest().joinToString("") { "%02x".format(it.toInt() and 255) }
    if (actual != expected) throw IOException("Receipt guide changed")
    return file.absolutePath
}
