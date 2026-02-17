package com.programmernexus.lifeque

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // The home_widget package stores the rendered image path in SharedPreferences
                // under the key provided in Dart's renderFlutterWidget(key: '...')
                val imagePath = widgetData.getString("prayer_widget_image", null)

                if (imagePath != null) {
                    val imageFile = java.io.File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.prayer_widget_image, bitmap)
                            setViewVisibility(R.id.prayer_widget_image, View.VISIBLE)
                        } else {
                            setViewVisibility(R.id.prayer_widget_image, View.GONE)
                        }
                    } else {
                        setViewVisibility(R.id.prayer_widget_image, View.GONE)
                    }
                } else {
                    // No image rendered yet — try common file paths as fallback
                    val possiblePaths = listOf(
                        java.io.File(context.filesDir, "prayer_widget_image.png"),
                        java.io.File(context.filesDir, "prayer_widget_image"),
                        java.io.File(context.cacheDir, "prayer_widget_image.png"),
                        java.io.File(context.cacheDir, "prayer_widget_image")
                    )
                    val file = possiblePaths.firstOrNull { it.exists() }
                    if (file != null) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.prayer_widget_image, bitmap)
                            setViewVisibility(R.id.prayer_widget_image, View.VISIBLE)
                        } else {
                            setViewVisibility(R.id.prayer_widget_image, View.GONE)
                        }
                    } else {
                        setViewVisibility(R.id.prayer_widget_image, View.GONE)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
