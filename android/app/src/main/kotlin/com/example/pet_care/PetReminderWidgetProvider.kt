package com.example.pet_care

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PetReminderWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            Log.d("PetReminderWidget", "Updating widget ID: $widgetId")
            
            val views = RemoteViews(context.packageName, R.layout.widget_pet_reminder).apply {
                // Lấy dữ liệu từ SharedPreferences (được lưu bởi HomeWidget.saveWidgetData trong Flutter)
                val petName = widgetData.getString("petName", "Pet Care")
                val reminderTitle = widgetData.getString("reminderTitle", "Không có lịch nhắc")
                val time = widgetData.getString("time", "--:--")

                Log.d("PetReminderWidget", "Data: $petName, $reminderTitle, $time")

                // Map dữ liệu vào các TextView trong layout
                setTextViewText(R.id.widget_pet_name, petName)
                setTextViewText(R.id.widget_reminder_title, reminderTitle)
                setTextViewText(R.id.widget_time, time)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
