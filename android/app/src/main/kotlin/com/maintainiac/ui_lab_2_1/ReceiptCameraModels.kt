package com.maintainiac.ui_lab_2_1

internal data class LiveReceiptFraming(
    val found: Boolean = false,
    val widthRatio: Double = 0.0,
    val heightRatio: Double = 0.0,
    val edgeCoverage: Double = 0.0,
    val confidenceBucket: String = "unknown",
    val touchesEdge: Boolean = false,
    val leftRatio: Double = 0.0,
    val topRatio: Double = 0.0,
    val rightRatio: Double = 1.0,
    val bottomRatio: Double = 1.0,
)
