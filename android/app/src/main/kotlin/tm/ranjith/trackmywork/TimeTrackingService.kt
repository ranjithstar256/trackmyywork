package tm.ranjith.trackmywork

import android.app.Service
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.IBinder
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log
import android.os.PowerManager

class TimeTrackingService : Service() {
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "activity_tracking_channel"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Log.d("TimeTrackingService", "Service created")

        // Create a wake lock to keep the CPU active
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "TrackmyWork:TimeTrackingWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimeTrackingService", "Service started: ${intent?.action}")

        when (intent?.action) {
            "START_TRACKING" -> {
                val activityName = intent.getStringExtra("activityName") ?: "Unknown Activity"
                val iconName = intent.getStringExtra("iconName") ?: "access_time"
                startForegroundService(activityName, iconName)
            }
            "UPDATE_TRACKING" -> {
                val activityName = intent.getStringExtra("activityName") ?: "Unknown Activity"
                val formattedTime = intent.getStringExtra("formattedTime") ?: "00:00:00"
                val iconName = intent.getStringExtra("iconName") ?: "access_time"
                updateNotification(activityName, formattedTime, iconName)
            }
            "STOP_TRACKING" -> {
                stopSelf()
            }
            "HEARTBEAT" -> {
                // Just wake up the service, no need to do anything specific
                Log.d("TimeTrackingService", "Heartbeat received")
            }
        }

        // If the service is killed, restart it
        return START_STICKY
    }

    private fun startForegroundService(activityName: String, iconName: String) {
        val notification = createNotification(activityName, "00:00:00", iconName)
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun updateNotification(activityName: String, formattedTime: String, iconName: String) {
        val notification = createNotification(activityName, formattedTime, iconName)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(activityName: String, formattedTime: String, iconName: String): Notification {
        // Create an intent that opens the app when the notification is tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create stop action intent
        val stopIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "STOP_TRACKING"
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Get icon resource ID (reuse the method or fallback to default)
        val iconResourceId = android.R.drawable.ic_media_play // Default icon

        // Build the notification
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TrackMyWork")
            .setContentText("Currently tracking: $activityName ($formattedTime)")
            .setSmallIcon(iconResourceId)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
        Log.d("TimeTrackingService", "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}