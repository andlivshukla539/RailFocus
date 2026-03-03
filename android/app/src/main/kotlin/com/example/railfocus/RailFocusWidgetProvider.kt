package com.example.railfocus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

/**
 * ═══════════════════════════════════════════════════════════════
 *  RailFocus Home Widget Provider
 *  Reads stats from SharedPreferences (written by Flutter's
 *  HomeWidgetService) and updates the widget layout.
 * ═══════════════════════════════════════════════════════════════
 */
class RailFocusWidgetProvider : AppWidgetProvider() {

    companion object {
        // SharedPreferences file used by Flutter's shared_preferences plugin
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // Station emojis matching level_up_overlay.dart
        private val STATION_EMOJIS = arrayOf(
            "🏗️", "🪵", "🚏", "🏠", "🏘️",
            "🏢", "🏙️", "🏛️", "🎭", "👑", "🌟"
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Read data from SharedPreferences (Flutter writes here)
        val prefs: SharedPreferences = context.getSharedPreferences(
            PREFS_NAME, Context.MODE_PRIVATE
        )

        // Flutter's shared_preferences plugin prefixes keys with "flutter."
        val streak = prefs.getLong("flutter.widget_streak", 0).toInt()
        val hours = prefs.getFloat("flutter.widget_hours", 0f)
        val todayMinutes = prefs.getLong("flutter.widget_today_minutes", 0).toInt()
        val stationLevel = prefs.getLong("flutter.widget_station_level", 0).toInt()

        // Build the RemoteViews
        val views = RemoteViews(context.packageName, R.layout.widget_railfocus)

        // Station emoji
        val clampedLevel = stationLevel.coerceIn(0, STATION_EMOJIS.size - 1)
        views.setTextViewText(R.id.widget_station_emoji, STATION_EMOJIS[clampedLevel])

        // Level text
        views.setTextViewText(R.id.widget_level, "LV $stationLevel")

        // Streak
        views.setTextViewText(R.id.widget_streak, "$streak")

        // Today's focus
        val todayStr = if (todayMinutes >= 60) {
            "${todayMinutes / 60}h${todayMinutes % 60}m"
        } else {
            "${todayMinutes}m"
        }
        views.setTextViewText(R.id.widget_today, todayStr)

        // Total hours
        val totalStr = if (hours >= 1) {
            String.format("%.1fh", hours)
        } else {
            "${(hours * 60).toInt()}m"
        }
        views.setTextViewText(R.id.widget_total, totalStr)

        // Tap widget → open app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
