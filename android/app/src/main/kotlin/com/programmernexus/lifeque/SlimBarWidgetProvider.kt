package com.programmernexus.lifeque

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/// Hosts the Flutter-rendered "Next prayer bar" image.
class SlimBarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            WidgetSizeReporter.report(context, appWidgetManager, widgetId, "slim_bar_widget_image")

            val views = RemoteViews(context.packageName, R.layout.slim_bar_widget_layout).apply {
                val imagePath = widgetData.getString("slim_bar_widget_image", null)
                val file = imagePath?.let { java.io.File(it) }
                    ?.takeIf { it.exists() }
                    ?: java.io.File(context.filesDir, "slim_bar_widget_image.png").takeIf { it.exists() }

                if (file != null) {
                    BitmapFactory.decodeFile(file.absolutePath)?.let { bitmap ->
                        setImageViewBitmap(R.id.slim_bar_widget_image, bitmap)
                        setViewVisibility(R.id.slim_bar_widget_image, View.VISIBLE)
                        setViewVisibility(R.id.slim_bar_widget_default, View.GONE)
                    }
                }

                // Tapping anywhere opens the app.
                context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
                    it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    setOnClickPendingIntent(
                        R.id.slim_bar_widget_root,
                        PendingIntent.getActivity(
                            context, 0, it,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                    )
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Keeps the reported size current when the user resizes the widget. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        WidgetSizeReporter.report(context, appWidgetManager, appWidgetId, "slim_bar_widget_image")
    }
}
