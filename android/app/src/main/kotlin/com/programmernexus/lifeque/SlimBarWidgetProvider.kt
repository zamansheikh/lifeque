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
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/// Hosts the Flutter-rendered "Next prayer bar" image.
class SlimBarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        WidgetSizeReporter.reportAll(context, appWidgetManager, appWidgetIds, "slim_bar_widget_image")

        appWidgetIds.forEach { widgetId ->
            val sizeTag = WidgetSizeReporter.sizeTag(appWidgetManager, widgetId)
            WidgetRender.ensureSized(context, widgetData, "slim_bar_widget_image", sizeTag)
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, widgetData, sizeTag))
        }
    }

    /**
     * Every update broadcast — including one with no instances placed, which
     * the base class ignores — refreshes the launcher-picker preview.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            WidgetPreviewPusher.push(context, SlimBarWidgetProvider::class.java, "slim_bar_widget_image") {
                buildViews(context, HomeWidgetPlugin.getData(context), null)
            }
        }
    }

    /**
     * The RemoteViews for one instance. [sizeTag] picks the bitmap rendered
     * for that instance's cell; null takes the un-suffixed image, which is
     * what a fresh instance — or the picker preview — reads.
     */
    private fun buildViews(context: Context, widgetData: SharedPreferences, sizeTag: String?): RemoteViews =
        RemoteViews(context.packageName, R.layout.slim_bar_widget_layout).apply {
                // The "not loaded yet" wording comes from Flutter so it
                // follows the language chosen in the app, not the one the
                // phone happens to be set to. Falls back to the layout's
                // own text if the app has not written it yet.
                widgetData.getString("placeholder_slim_title", null)
                    ?.let { setTextViewText(R.id.slim_bar_placeholder_title, it) }
                widgetData.getString("placeholder_slim_body", null)
                    ?.let { setTextViewText(R.id.slim_bar_placeholder_body, it) }

                // The rendered image, if the app has produced one. An empty
                // path is how the app says "no location yet" — the placeholder
                // in this layout takes over, on this widget's own background.
                // This instance's own size first — two of the same widget at
                // different widths each get their own bitmap — then the
                // un-suffixed image, which is rendered before any size is known.
                val imagePath = sizeTag?.let { widgetData.getString("slim_bar_widget_image_$it", null) }
                    ?: widgetData.getString("slim_bar_widget_image", null)
                val file = if (imagePath.isNullOrEmpty()) null else
                    java.io.File(imagePath).takeIf { it.exists() }
                        ?: java.io.File(context.filesDir, "slim_bar_widget_image.png")
                            .takeIf { it.exists() }
                val bitmap = file?.let { BitmapFactory.decodeFile(it.absolutePath) }

                // Both visibilities are set every time rather than left to the
                // layout's defaults. Each update re-inflates these RemoteViews,
                // so a widget that already has an image would otherwise show
                // its placeholder for a frame first — the flash on launch.
                if (bitmap != null) {
                    setImageViewBitmap(R.id.slim_bar_widget_image, bitmap)
                    setViewVisibility(R.id.slim_bar_widget_image, View.VISIBLE)
                    setViewVisibility(R.id.slim_bar_widget_default, View.GONE)
                } else {
                    setViewVisibility(R.id.slim_bar_widget_image, View.GONE)
                    setViewVisibility(R.id.slim_bar_widget_default, View.VISIBLE)
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

    /** Keeps the reported size current when the user resizes the widget. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val ids = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(context, SlimBarWidgetProvider::class.java)
        )
        WidgetSizeReporter.reportAll(context, appWidgetManager, ids, "slim_bar_widget_image")
        WidgetRender.ensureSized(
            context,
            HomeWidgetPlugin.getData(context),
            "slim_bar_widget_image",
            WidgetSizeReporter.sizeTag(appWidgetManager, appWidgetId)
        )
    }
}
