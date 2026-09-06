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
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MosqueTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            WidgetSizeReporter.report(context, appWidgetManager, widgetId, "mosque_widget_image")

            val views = RemoteViews(context.packageName, R.layout.mosque_widget_layout).apply {
                // The "not loaded yet" wording comes from Flutter so it
                // follows the language chosen in the app, not the one the
                // phone happens to be set to. Falls back to the layout's
                // own text if the app has not written it yet.
                widgetData.getString("placeholder_mosque_title", null)
                    ?.let { setTextViewText(R.id.mosque_placeholder_title, it) }
                widgetData.getString("placeholder_mosque_body", null)
                    ?.let { setTextViewText(R.id.mosque_placeholder_body, it) }

                // Load the rendered image from the path stored by home_widget
                val imagePath = widgetData.getString("mosque_widget_image", null)
                var imageLoaded = false

                if (imagePath != null) {
                    val imageFile = java.io.File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.mosque_widget_image, bitmap)
                            setViewVisibility(R.id.mosque_widget_image, View.VISIBLE)
                            setViewVisibility(R.id.mosque_widget_default, View.GONE)
                            imageLoaded = true
                        }
                    }
                }

                if (!imageLoaded) {
                    val possiblePaths = listOf(
                        java.io.File(context.filesDir, "mosque_widget_image.png"),
                        java.io.File(context.filesDir, "mosque_widget_image")
                    )
                    val file = possiblePaths.firstOrNull { it.exists() }
                    if (file != null) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.mosque_widget_image, bitmap)
                            setViewVisibility(R.id.mosque_widget_image, View.VISIBLE)
                            setViewVisibility(R.id.mosque_widget_default, View.GONE)
                        }
                    }
                }

                // Tapping opens the app *on the prayer screen*, not on whatever
                // the user's home page happens to be. Every one of these
                // widgets is about prayer times, so landing on the task list
                // made you navigate there yourself every time.
                setOnClickPendingIntent(
                    R.id.mosque_widget_image,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse(WidgetRoutes.PRAYER)
                    )
                )

                // ── Refresh button tap → trigger Dart background callback to re-render ──
                val refreshPending = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homewidget://refreshwidget")
                )
                setOnClickPendingIntent(R.id.mosque_refresh_button, refreshPending)
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
        WidgetSizeReporter.report(context, appWidgetManager, appWidgetId, "mosque_widget_image")
    }
}
