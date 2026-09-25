package com.maintainiac.ui_lab_2_1

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import androidx.exifinterface.media.ExifInterface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File
import java.io.FilterOutputStream
import java.io.OutputStream
import android.os.StatFs

/** Local derived images only. Serial background task queue, never the UI thread. */
class ReceiptRegionBridge(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "maintainiac/receipt_regions", StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()).setMethodCallHandler { call, result ->
            if (call.method != "describe" && call.method != "decode") {
                result.notImplemented()
            } else {
                try {
                    result.success(process(call))
                } catch (_: Exception) {
                    // Do not leak local paths or image metadata through platform errors.
                    result.error("receipt_region_failed", "This image section could not be prepared safely.", null)
                } catch (_: OutOfMemoryError) {
                    result.error("receipt_region_memory", "There is not enough memory to read this image safely.", null)
                }
            }
        }
    }

    private fun process(call: MethodCall): Map<String, Any> {
        val source = File(requireNotNull(call.argument<String>("path")))
        val maxBytes = requireNotNull(call.argument<Int>("maxBytes"))
        require(maxBytes in 1..(32 * 1024 * 1024))
        require(source.isFile && source.length() in 1..maxBytes.toLong())
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(source.path, bounds)
        val rawWidth = bounds.outWidth
        val rawHeight = bounds.outHeight
        require(rawWidth in 1..30000 && rawHeight in 1..30000)
        require(rawWidth.toLong() * rawHeight <= 100000000)
        val orientation = ExifInterface(source).getAttributeInt(
            ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        val swap = orientation in 5..8
        val width = if (swap) rawHeight else rawWidth
        val height = if (swap) rawWidth else rawHeight
        if (call.method == "describe") return mapOf("width" to width, "height" to height)
        val top = requireNotNull(call.argument<Int>("top"))
        val bottom = requireNotNull(call.argument<Int>("bottom"))
        val sample = requireNotNull(call.argument<Int>("sampleSize"))
        val maxPixels = requireNotNull(call.argument<Int>("maxPixels"))
        require(top >= 0 && bottom > top && bottom <= height)
        require(sample in 1..32 && sample and (sample - 1) == 0)
        require(maxPixels in 100000..3000000)
        require(((width + sample - 1) / sample).toLong() *
            ((bottom - top + sample - 1) / sample) <= maxPixels)
        val transform = orientationMatrix(orientation, rawWidth, rawHeight)
        val inverse = Matrix()
        require(transform.invert(inverse))
        val rawRegion = RectF(0f, top.toFloat(), width.toFloat(), bottom.toFloat())
        inverse.mapRect(rawRegion)
        val region = Rect(rawRegion.left.toInt(), rawRegion.top.toInt(),
            rawRegion.right.toInt(), rawRegion.bottom.toInt())
        @Suppress("DEPRECATION")
        val decoder = requireNotNull(BitmapRegionDecoder.newInstance(source.path, false))
        var raw: Bitmap? = null
        var upright: Bitmap? = null
        var output: File? = null
        try {
            raw = requireNotNull(decoder.decodeRegion(region, BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }))
            require(raw.width.toLong() * raw.height <= maxPixels)
            upright = Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, transform, false)
            require(StatFs(context.cacheDir.absolutePath).availableBytes >=
                100L * 1024 * 1024 + 16L * 1024 * 1024)
            output = File.createTempFile("receipt-ocr-region-", ".png", context.cacheDir)
            BoundedOcrOutput(output.outputStream()).use {
                require(upright.compress(Bitmap.CompressFormat.PNG, 100, it))
            }
            return mapOf("path" to output.path, "width" to upright.width, "height" to upright.height)
        } finally {
            if (upright !== raw) upright?.recycle()
            raw?.recycle()
            decoder.recycle()
        }
    }

    private fun orientationMatrix(orientation: Int, width: Int, height: Int): Matrix {
        val w = width.toFloat()
        val h = height.toFloat()
        val values = when (orientation) {
            2 -> floatArrayOf(-1f, 0f, w, 0f, 1f, 0f, 0f, 0f, 1f)
            3 -> floatArrayOf(-1f, 0f, w, 0f, -1f, h, 0f, 0f, 1f)
            4 -> floatArrayOf(1f, 0f, 0f, 0f, -1f, h, 0f, 0f, 1f)
            5 -> floatArrayOf(0f, 1f, 0f, 1f, 0f, 0f, 0f, 0f, 1f)
            6 -> floatArrayOf(0f, -1f, h, 1f, 0f, 0f, 0f, 0f, 1f)
            7 -> floatArrayOf(0f, -1f, h, -1f, 0f, w, 0f, 0f, 1f)
            8 -> floatArrayOf(0f, 1f, 0f, -1f, 0f, w, 0f, 0f, 1f)
            else -> floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
        }
        return Matrix().apply { setValues(values) }
    }
}

private class BoundedOcrOutput(output: OutputStream) : FilterOutputStream(output) {
    private var written = 0L
    private fun admit(count: Int) {
        require(count >= 0 && written + count <= 16L * 1024 * 1024)
        written += count
    }
    override fun write(value: Int) { admit(1); out.write(value) }
    override fun write(bytes: ByteArray, offset: Int, count: Int) {
        admit(count); out.write(bytes, offset, count)
    }
}
