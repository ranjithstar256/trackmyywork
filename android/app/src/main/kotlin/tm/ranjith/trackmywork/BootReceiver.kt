package tm.ranjith.trackmywork

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.content.SharedPreferences
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted, checking if we need to restart time tracking")

            // Check shared preferences to see if we were tracking an activity before device shutdown
            val prefs = context.getSharedPreferences("TrackmyWork", Context.MODE_PRIVATE)
            val isTracking = prefs.getBoolean("is_tracking", false)

            if (isTracking) {
                val activityId = prefs.getString("active_activity_id", null)
                val activityName = prefs.getString("active_activity_name", "Unknown Activity")
                val activityIcon = prefs.getString("active_activity_icon", "access_time")

                if (activityId != null) {
                    Log.d("BootReceiver", "Restarting time tracking for: $activityName")

                    // Start the time tracking service
                    val serviceIntent = Intent(context, TimeTrackingService::class.java).apply {
                        action = "START_TRACKING"
                        putExtra("activityName", activityName)
                        putExtra("iconName", activityIcon)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                }
            }
        }
    }
}