package com.programmernexus.lifeque

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * Asks the Flutter side to re-render when a widget instance has a size no
 * bitmap exists for yet.
 *
 * A widget just placed, or just resized, reads the un-suffixed image — the
 * one rendered for whichever size was known at the time — and the launcher
 * crops it to the new cell until the next scheduled render, up to fifteen
 * minutes later. That was the mosque widget with its edges cut off. Reporting
 * the size (done just before this) and then asking for a render closes the
 * gap in a second or two.
 *
 * One render redraws every widget type, so the throttle is shared: when
 * three providers notice new sizes in the same update pass, one request
 * covers them all. It also stops a render that fails to produce the sized
 * image from spinning — one request per half minute is plenty.
 */
object WidgetRender {
    private const val PREFERENCES = "HomeWidgetPreferences"
    private const val MIN_GAP_MS = 30_000L

    fun ensureSized(
        context: Context,
        widgetData: SharedPreferences,
        key: String,
        sizeTag: String?
    ) {
        if (sizeTag == null) return
        if (widgetData.getString("${key}_$sizeTag", null) != null) return

        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val stampKey = "widgets_rerender_at"
        val now = System.currentTimeMillis()
        if (now - prefs.getLong(stampKey, 0L) < MIN_GAP_MS) return
        prefs.edit().putLong(stampKey, now).apply()

        HomeWidgetBackgroundIntent
            .getBroadcast(context, Uri.parse("homewidget://refreshwidget"))
            .send()
    }
}
