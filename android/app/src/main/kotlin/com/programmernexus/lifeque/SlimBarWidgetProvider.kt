package com.programmernexus.lifeque

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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
                // The "not loaded yet" wording comes from Flutter so it
                // follows the language chosen in the app, not the one the
                // phone happens to be set to. Falls back to the layout's
                // own text if the app has not written it yet.
                widgetData.getString("placeholder_slim_title", null)
                    ?.let { setTextViewText(R.id.slim_bar_placeholder_title, it) }
                widgetData.getString("placeholder_slim_body", null)
                    ?.let { setTextViewText(R.id.slim_bar_placeholder_body, it) }

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

                // Tapping opens the app *on the prayer screen*, not on whatever
                // the user's home page happens to be. Every one of these
                // widgets is about prayer times, so landing on the task list
                // made you navigate there yourself every time.
                setOnClickPendingIntent(
                    R.id.slim_bar_widget_root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse(WidgetRoutes.PRAYER)
                    )
                )
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
