package com.programmernexus.lifeque

import android.appwidget.AppWidgetManager
import android.content.Context

/**
 * Publishes each widget's real cell size so the Flutter side can render an
 * image that matches it exactly.
 *
 * Without this the Dart layer renders one fixed size for every device: with
 * scaleType="fitXY" that stretches the text on any cell with a different
 * aspect, and with "centerCrop" it clips. Reporting the size removes both.
 *
 * Sizes are published as a *set* per widget type, not a single value. A
 * launcher can hold two of the same widget at different widths — the case
 * this replaced held one size per type, last writer wins, so one instance
 * always got a bitmap rendered for the other and showed it cropped.
 *
 * Values land in home_widget's own SharedPreferences, which is the same store
 * `HomeWidget.getWidgetData` reads from, as "<w>x<h>" strings because that
 * crosses the platform channel unambiguously.
 */
object WidgetSizeReporter {
    private const val PREFERENCES = "HomeWidgetPreferences"

    /**
     * "465x350" for this instance, or null if the launcher has not sized it.
     *
     * Portrait gives the narrowest width and tallest height; using that pair
     * keeps the render from overflowing when the device rotates. The provider
     * builds its bitmap lookup key from this same string, so it must match
     * what Flutter is handed byte for byte.
     */
    fun sizeTag(appWidgetManager: AppWidgetManager, appWidgetId: Int): String? {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (width <= 0 || height <= 0) return null
        return "${width}x${height}"
    }

    /**
     * Publishes every distinct size among [appWidgetIds] under "<key>_sizes",
     * and the last under "<key>_size" for readers that only know one.
     *
     * Rebuilt from the full id list on every call rather than appended to, so
     * a size a widget was resized away from does not linger and cost the
     * background job a render forever.
     */
    fun reportAll(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        key: String
    ) {
        val tags = appWidgetIds.toList().mapNotNull { id -> sizeTag(appWidgetManager, id) }.distinct()
        if (tags.isEmpty()) return
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString("${key}_sizes", tags.joinToString(","))
            .putString("${key}_size", tags.last())
            .apply()
    }
}
