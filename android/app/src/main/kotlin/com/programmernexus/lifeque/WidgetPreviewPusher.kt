package com.programmernexus.lifeque

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/**
 * Hands the launcher's widget picker a live preview on Android 15+.
 *
 * The static `previewLayout` in the widget info is resolved by the launcher
 * in the *phone's* locale, so on an English phone the picker showed English
 * previews for a Bangla app, with no way to say otherwise from resources.
 * `setWidgetPreview` sidesteps that: the preview is a RemoteViews built here,
 * carrying the same bitmap the widget itself shows — same language, same
 * font, same everything. Older Android keeps the static preview.
 *
 * The system rate-limits this call, so it is pushed only when something the
 * preview depends on has changed: the language, whether a real image exists,
 * or the six-hour slot of the day (so the times on it stay roughly current).
 */
object WidgetPreviewPusher {
    private const val PREFERENCES = "HomeWidgetPreferences"

    fun push(context: Context, provider: Class<*>, key: String, build: () -> RemoteViews) {
        if (Build.VERSION.SDK_INT < 35) return

        val widgetData = HomeWidgetPlugin.getData(context)
        val language = widgetData.getString("widget_language", "?")
        val hasImage = !widgetData.getString(key, null).isNullOrEmpty()
        val cal = Calendar.getInstance()
        val slot = cal.get(Calendar.DAY_OF_YEAR) * 4 + cal.get(Calendar.HOUR_OF_DAY) / 6
        val stamp = "$language|$hasImage|$slot"

        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val stampKey = "${key}_preview_stamp"
        if (prefs.getString(stampKey, null) == stamp) return

        val manager = context.getSystemService(AppWidgetManager::class.java) ?: return
        val accepted = manager.setWidgetPreview(
            ComponentName(context, provider),
            AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN,
            build()
        )
        if (accepted) prefs.edit().putString(stampKey, stamp).apply()
    }
}
