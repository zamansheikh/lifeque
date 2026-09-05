package com.programmernexus.lifeque

import android.appwidget.AppWidgetManager
import android.content.Context

/**
 * Publishes each widget's real cell size so the Flutter side can render an
 * image that matches it exactly.
 *
 * Without this the Dart layer renders one fixed size for every device: with
 * scaleType="fitXY" that stretches the text on any cell with a different
 * aspect, and with "fitCenter" it letterboxes, leaving the card floating
 * inside the widget's background. Reporting the size removes both.
 *
 * Values land in home_widget's own SharedPreferences, which is the same store
 * `HomeWidget.getWidgetData` reads from. They're written as "<w>x<h>" strings
 * because that crosses the platform channel unambiguously.
 */
object WidgetSizeReporter {
    private const val PREFERENCES = "HomeWidgetPreferences"

    fun report(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        key: String
    ) {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        // Portrait gives the narrowest width and tallest height; using that
        // pair keeps the render from overflowing when the device rotates.
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (width <= 0 || height <= 0) return

        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString("${key}_size", "${width}x${height}")
            .apply()
    }
}
