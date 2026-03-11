package com.example.bitaqwa

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrayerWidgetProvider::class.java)
        )

        when (intent.action) {
            ACTION_REFRESH_PRAYER -> {
                // Trigger background refresh in Flutter
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homeWidgetPrayer://refresh")
                )
                backgroundIntent.send()
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                ids.forEach { updateWidget(context, manager, it) }
            }
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)
        val prefs = HomeWidgetPlugin.getData(context)

        val location = prefs.getString("prayer_location", "-") ?: "-"
        val next = prefs.getString("prayer_next", "-") ?: "-"
        
        // Individual times
        val subuh = prefs.getString("time_subuh", "-") ?: "-"
        val dzuhur = prefs.getString("time_dzuhur", "-") ?: "-"
        val ashar = prefs.getString("time_ashar", "-") ?: "-"
        val maghrib = prefs.getString("time_maghrib", "-") ?: "-"
        val isya = prefs.getString("time_isya", "-") ?: "-"
        val active = prefs.getString("active_prayer", "") ?: ""

        views.setTextViewText(R.id.tv_location, location)
        views.setTextViewText(R.id.tv_next, next)
        
        views.setTextViewText(R.id.tv_subuh, subuh)
        views.setTextViewText(R.id.tv_dzuhur, dzuhur)
        views.setTextViewText(R.id.tv_ashar, ashar)
        views.setTextViewText(R.id.tv_maghrib, maghrib)
        views.setTextViewText(R.id.tv_isya, isya)

        // Reset backgrounds
        val items = mapOf(
            "Shubuh" to R.id.item_subuh,
            "Dzuhur" to R.id.item_dzuhur,
            "Ashar" to R.id.item_ashar,
            "Maghrib" to R.id.item_maghrib,
            "Isya" to R.id.item_isya
        )

        items.values.forEach { 
             views.setInt(it, "setBackgroundResource", 0) 
        }

        // Highlight active
        items[active]?.let {
            views.setInt(it, "setBackgroundResource", R.drawable.widget_item_active_bg)
        }

        // Refresh Button -> menggunakan broadcast ke diri sendiri (PrayerWidgetProvider)
        // yang nanti akan men-trigger HomeWidgetBackgroundIntent
        val refreshIntent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = ACTION_REFRESH_PRAYER
        }
        val pending = PendingIntent.getBroadcast(
            context,
            0,
            refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_refresh, pending)

        manager.updateAppWidget(widgetId, views)
    }

    companion object {
        const val ACTION_REFRESH_PRAYER = "com.example.bitaqwa.ACTION_REFRESH_PRAYER"
    }
}
