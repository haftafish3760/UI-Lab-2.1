package com.maintainiac.ui_lab_2_1

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView

internal fun ReceiptCameraActivity.settingSwitch(
    title: String,
    detail: String,
    checked: Boolean,
    onChanged: (Boolean) -> Unit,
): View {
    val activity = this
    val row = settingCard().apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }
    row.addView(LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.rgb(232, 236, 238))
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(200, 208, 211))
            textSize = 12f
        })
    })
    val checkedLabel = receiptCameraText("ON", "SÍ")
    val uncheckedLabel = receiptCameraText("OFF", "NO")
    val toggle = Switch(this).apply {
        isChecked = checked
        textOn = checkedLabel
        textOff = uncheckedLabel
        showText = true
        minimumWidth = dp(76)
        setPadding(dp(8), 0, 0, 0)
        setTextColor(Color.WHITE)
        thumbTintList = ColorStateList(
            arrayOf(
                intArrayOf(android.R.attr.state_checked),
                intArrayOf(-android.R.attr.state_checked),
            ),
            intArrayOf(Color.rgb(255, 209, 102), Color.rgb(214, 222, 225)),
        )
        trackTintList = ColorStateList(
            arrayOf(
                intArrayOf(android.R.attr.state_checked),
                intArrayOf(-android.R.attr.state_checked),
            ),
            intArrayOf(Color.rgb(101, 81, 30), Color.rgb(70, 82, 88)),
        )
        contentDescription = "$title: ${if (checked) checkedLabel else uncheckedLabel}"
        setOnCheckedChangeListener { button, isNowChecked ->
            button.contentDescription =
                "$title: ${if (isNowChecked) checkedLabel else uncheckedLabel}"
            onChanged(isNowChecked)
        }
    }
    row.addView(toggle)
    row.isClickable = true
    row.isFocusable = true
    row.setOnClickListener { toggle.isChecked = !toggle.isChecked }
    return row
}

internal fun ReceiptCameraActivity.settingSummary(title: String, detail: String): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.rgb(232, 236, 238))
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(200, 208, 211))
            textSize = 12f
        })
    }
}

internal fun ReceiptCameraActivity.settingSlider(
    title: String,
    detail: String,
    enabled: Boolean,
    maximum: Int,
    current: Int,
    onChanged: (Int) -> Unit,
    onReset: () -> Unit,
): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.rgb(232, 236, 238))
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(200, 208, 211))
            textSize = 12f
        })
        addView(LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(SeekBar(activity).apply {
                isEnabled = enabled
                max = maximum.coerceAtLeast(0)
                progress = current.coerceIn(0, max)
                alpha = if (enabled) 1f else 0.45f
                contentDescription = title
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1f,
                )
                setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                    override fun onProgressChanged(
                        seekBar: SeekBar?,
                        progress: Int,
                        fromUser: Boolean,
                    ) {
                        if (fromUser) onChanged(progress)
                    }

                    override fun onStartTrackingTouch(seekBar: SeekBar?) = Unit
                    override fun onStopTrackingTouch(seekBar: SeekBar?) = Unit
                })
            })
            addView(Button(activity).apply {
                text = receiptCameraText("Reset", "Restablecer")
                isAllCaps = false
                isEnabled = enabled
                setTextColor(Color.rgb(255, 209, 102))
                setOnClickListener { onReset() }
            })
        })
    }
}

internal fun ReceiptCameraActivity.settingChoiceGroup(
    title: String,
    detail: String,
    selectedValue: String,
    options: List<Pair<String, String>>,
    onChanged: (String) -> Unit,
): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = title
            setTextColor(Color.rgb(232, 236, 238))
            textSize = 15f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(200, 208, 211))
            textSize = 12f
        })
        addView(LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(6), 0, 0)
            options.forEach { (value, label) ->
                addView(Button(activity).apply {
                    text = label
                    isAllCaps = false
                    isSelected = value == selectedValue
                    setTextColor(if (isSelected) Color.BLACK else Color.WHITE)
                    setBackgroundColor(
                        if (isSelected) {
                            Color.rgb(255, 209, 102)
                        } else {
                            Color.rgb(17, 24, 27)
                        },
                    )
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ).apply {
                        topMargin = dp(3)
                        bottomMargin = dp(3)
                    }
                    setOnClickListener {
                        onChanged(value)
                    }
                })
            }
        })
    }
}

internal fun ReceiptCameraActivity.settingSectionHeader(title: String): View {
    return TextView(this).apply {
        text = title
        setTextColor(Color.rgb(255, 209, 102))
        textSize = 12f
        setTypeface(typeface, Typeface.BOLD)
        setPadding(dp(2), dp(13), dp(2), dp(5))
    }
}

internal fun ReceiptCameraActivity.settingMetricRow(
    label: String,
    value: String,
    detail: String,
): View {
    val activity = this
    return settingCard().apply {
        orientation = LinearLayout.VERTICAL
        addView(TextView(activity).apply {
            text = label
            setTextColor(Color.rgb(149, 163, 168))
            textSize = 11f
            setTypeface(typeface, Typeface.BOLD)
        })
        addView(TextView(activity).apply {
            text = value
            setTextColor(Color.rgb(255, 209, 102))
            textSize = 19f
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, dp(2), 0, dp(2))
        })
        addView(TextView(activity).apply {
            text = detail
            setTextColor(Color.rgb(200, 208, 211))
            textSize = 12f
        })
    }
}

private fun ReceiptCameraActivity.settingCard(): LinearLayout {
    return LinearLayout(this).apply {
        setPadding(dp(12), dp(10), dp(12), dp(10))
        background = GradientDrawable().apply {
            setColor(Color.rgb(14, 20, 22))
            cornerRadius = dp(6).toFloat()
            setStroke(dp(1), Color.rgb(61, 74, 80))
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            bottomMargin = dp(8)
        }
    }
}
