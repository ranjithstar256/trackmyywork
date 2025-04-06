package tm.ranjith.trackmywork

import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import android.graphics.Color
import android.app.PendingIntent
import android.content.Intent
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.Manifest
import android.R
import android.provider.Settings
import android.net.Uri
import android.util.Log
import android.graphics.BitmapFactory
import android.content.res.Resources
import android.os.BatteryManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "tm.ranjith.trackmywork/notification"
    private val STOP_TRACKING_CHANNEL = "STOP_TRACKING"
    private val notificationChannelId = "activity_tracking_channel"
    private val notificationId = 1 // Use a consistent notification ID for all updates
    private val notificationChannelName = "Activity Tracking"
    private val notificationChannelDescription = "Shows currently tracked activity"
    private val NOTIFICATION_PERMISSION_CODE = 123
    
    // Store the Flutter engine for later use
    private lateinit var flutterEngine: FlutterEngine

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Store the Flutter engine
        this.flutterEngine = flutterEngine

        // Create notification channel for Android O and above
        createNotificationChannel()

        // Check if app was opened from notification action
        val action = intent.getStringExtra("action")
        if (action == "STOP_TRACKING") {
            // Send a message to Flutter to stop tracking
            sendStopTrackingMessage()
        }

        // Setup method channel for notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showNotification" -> {
                    // Get parameters from method call
                    val id = call.argument<Int>("id") ?: notificationId
                    val title = call.argument<String>("title") ?: "TrackMyWork"
                    val body = call.argument<String>("body") ?: ""
                    val iconName = call.argument<String>("iconName") ?: "access_time"
                    val ongoing = call.argument<Boolean>("ongoing") ?: true

                    // Show the notification
                    showNotification(id, title, body, iconName, ongoing)
                    result.success(true)
                }
                "updateNotificationContent" -> {
                    // Get parameters from method call
                    val id = call.argument<Int>("id") ?: notificationId
                    val title = call.argument<String>("title") ?: "TrackMyWork"
                    val body = call.argument<String>("body") ?: ""
                    val iconName = call.argument<String>("iconName") ?: "access_time"

                    // Update the notification content without recreating it
                    updateNotificationContent(id, title, body, iconName)
                    result.success(true)
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id") ?: notificationId
                    cancelNotification(id)
                    result.success(true)
                }
                "requestNotificationPermissions" -> {
                    requestNotificationPermissions()
                    result.success(true)
                }
                "areNotificationsEnabled" -> {
                    val enabled = areNotificationsEnabled()
                    result.success(enabled)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup message channel for stop tracking
        BasicMessageChannel(flutterEngine.dartExecutor.binaryMessenger, STOP_TRACKING_CHANNEL, StringCodec.INSTANCE).setMessageHandler { message, reply ->
            if (message == "STOP_TRACKING") {
                Log.d("MainActivity", "Received STOP_TRACKING message from Flutter")
                // Handle stop tracking message
                reply.reply("Message received")
            } else {
                reply.reply(null)
            }
        }
        
        // Setup method channel for battery level
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tm.ranjith.trackmywork/battery").setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    result.success(batteryLevel)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // Helper method to send stop tracking message to Flutter
    private fun sendStopTrackingMessage() {
        try {
            val channel = BasicMessageChannel(
                flutterEngine.dartExecutor.binaryMessenger, 
                STOP_TRACKING_CHANNEL, 
                StringCodec.INSTANCE
            )
            channel.send("STOP_TRACKING")
            Log.d("MainActivity", "Sent STOP_TRACKING message to Flutter")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sending STOP_TRACKING message: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(notificationChannelId, notificationChannelName, importance).apply {
                description = notificationChannelDescription
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(false)
                setSound(null, null)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            Log.d("MainActivity", "Notification channel created: $notificationChannelId")
        }
    }

    private fun requestNotificationPermissions() {
        // For Android 13 (API level 33) and above, we need to request the notification permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }
    }

    private fun areNotificationsEnabled(): Boolean {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // For Android 13 (API level 33) and above, check if we have the notification permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        }

        // For Android 8.0 (API level 26) to Android 12.1 (API level 32)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.areNotificationsEnabled()
        } else {
            // For Android 7.1.1 (API level 25) and below
            true
        }
    }

    private fun getNotificationIcon(iconName: String): Int {
        // Get icon resource ID based on icon name
        val resources = resources
        // Try to get a custom icon for the notification
        val iconResourceId = resources.getIdentifier(
            "ic_notification_$iconName",
            "drawable",
            packageName
        )

        // If custom icon not found, use a fallback
        return if (iconResourceId != 0) {
            iconResourceId
        } else {
            android.R.drawable.ic_media_play // Make sure to create this default icon
        }
    }

    private fun showNotification(id: Int, title: String, body: String, iconName: String, ongoing: Boolean) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

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

        // Get the appropriate icon for the notification
        val iconResourceId = getNotificationIcon(iconName)

        // Build the notification
        val notificationBuilder = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(iconResourceId)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setOngoing(ongoing)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true) // Only alert once, very important for updates

        // For Android 5.0+ (Lollipop and above), set color
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            notificationBuilder.setColor(ContextCompat.getColor(this, R.color.darker_gray))
        }

        // Show the notification
        notificationManager.notify(id, notificationBuilder.build())
        Log.d("MainActivity", "Showing notification: $id, $title, $body")
    }

    private fun updateNotificationContent(id: Int, title: String, body: String, iconName: String) {
        // Use the same method as showNotification but ensure onlyAlertOnce is true
        // and use the same notification ID
        showNotification(id, title, body, iconName, true)
        Log.d("MainActivity", "Updating notification: $id, $title, $body")
    }

    private fun cancelNotification(id: Int) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
        Log.d("MainActivity", "Canceling notification: $id")
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, you can show notifications now
                Log.d("MainActivity", "Notification permission granted")
            } else {
                // Permission denied, you cannot show notifications
                Log.d("MainActivity", "Notification permission denied")
            }
        }
    }
    
    // Handle new intents when the app is already running
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        // Check if this intent has the STOP_TRACKING action
        val action = intent.getStringExtra("action")
        if (action == "STOP_TRACKING") {
            // Send a message to Flutter to stop tracking
            sendStopTrackingMessage()
        }
    }

    // Get battery level
    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }
}

class NotificationActionReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "STOP_TRACKING" -> {
                Log.d("NotificationActionReceiver", "Received STOP_TRACKING action")
                
                // Send a message to Flutter to stop tracking by launching the main activity
                // with a special action flag
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("action", "STOP_TRACKING")
                }
                context.startActivity(mainIntent)

                // Also directly cancel any existing notification
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.cancel(1) // Use the same notification ID as in MainActivity
                
                Log.d("NotificationActionReceiver", "Sent STOP_TRACKING intent to MainActivity")
            }
        }
    }
}