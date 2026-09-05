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
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Load the rendered image from the path stored by home_widget
                val imagePath = widgetData.getString("prayer_widget_image", null)
                var imageLoaded = false

                if (imagePath != null) {
                    val imageFile = java.io.File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.prayer_widget_image, bitmap)
                            setViewVisibility(R.id.prayer_widget_image, View.VISIBLE)
                            setViewVisibility(R.id.prayer_widget_default, View.GONE)
                            imageLoaded = true
                        }
                    }
                }

                if (!imageLoaded) {
                    val possiblePaths = listOf(
                        java.io.File(context.filesDir, "prayer_widget_image.png"),
                        java.io.File(context.filesDir, "prayer_widget_image")
                    )
                    val file = possiblePaths.firstOrNull { it.exists() }
                    if (file != null) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.prayer_widget_image, bitmap)
                            setViewVisibility(R.id.prayer_widget_image, View.VISIBLE)
                            setViewVisibility(R.id.prayer_widget_default, View.GONE)
                        }
                    }
                }

                // ── Main image tap → launch the app ──
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    val launchPending = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.prayer_widget_image, launchPending)
                }

                // ── Refresh button tap → trigger Dart background callback to re-render ──
                val refreshPending = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homewidget://refreshwidget")
                )
                setOnClickPendingIntent(R.id.refresh_button, refreshPending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
