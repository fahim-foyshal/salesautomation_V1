package com.example.salesautomation_v4

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.concurrent.TimeUnit

class LocationService : Service() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var locationClient: LocationClient
    private val binder = LocalBinder()
    private var locationCallback: LocationCallback? = null
    private lateinit var sharedPreferences: SharedPreferences
    private var isTrackingActive = false

    // Variables to track location and time spent
    private var lastLocation: Pair<Double, Double>? = null
    private var locationStartTime: Long = 0L

    // Define business hours
    private val startHour = 9   // 8:00 AM
    private val startMinute = 15
    private val endHour = 19    // 6:00 PM
    private val endMinute = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel() // Create notification channel
        sharedPreferences = getSharedPreferences("my_prefs", Context.MODE_PRIVATE)
        locationClient = DefaultLocationClient(
            applicationContext,
            LocationServices.getFusedLocationProviderClient(applicationContext)
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "location_channel"
            val channelName = "Location Updates"
            val channelDescription = "Channel for location update notifications"
            val importance = NotificationManager.IMPORTANCE_LOW

            val notificationChannel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(notificationChannel)
        }
    }

    fun getValueFromSharedPreferences(key: String): String? {
        return sharedPreferences.getString(key, null)
    }

    inner class LocalBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    fun setLocationCallback(callback: LocationCallback) {
        locationCallback = callback
    }

    private fun isWithinBusinessHours(): Boolean {
        return true // Always return true to disable time restrictions
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                start() // Directly start without time check
            }
            ACTION_STOP -> stop()
        }
        return START_STICKY
    }
    
    private fun scheduleNextBusinessHoursAction(isStart: Boolean) {
        serviceScope.launch {
            val calendar = Calendar.getInstance()
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
            val currentMinute = calendar.get(Calendar.MINUTE)
            val currentTimeInMinutes = currentHour * 60 + currentMinute
            
            val targetTimeInMinutes = if (isStart) {
                // If current time is before business hours, wait until start time
                // If current time is after business hours, wait until next day's start time
                if (currentTimeInMinutes < startHour * 60 + startMinute) {
                    startHour * 60 + startMinute
                } else {
                    // Next day's start time (adding 24 hours in minutes)
                    (startHour * 60 + startMinute) + (24 * 60)
                }
            } else {
                // Schedule to stop at end of business hours
                endHour * 60 + endMinute
            }
            
            // Calculate delay in milliseconds
            var delayInMinutes = targetTimeInMinutes - currentTimeInMinutes
            if (delayInMinutes < 0) {
                delayInMinutes += 24 * 60 // Add a day if negative
            }
            
            val delayInMillis = TimeUnit.MINUTES.toMillis(delayInMinutes.toLong())
            Log.d("LocationService", "Scheduling ${if (isStart) "start" else "stop"} in $delayInMinutes minutes")
            
            delay(delayInMillis)
            
            if (isStart) {
                start()
                // Schedule to stop at end of business hours
                scheduleNextBusinessHoursAction(false)
            } else {
                stop()
                // Schedule to start at next business hours
                scheduleNextBusinessHoursAction(true)
            }
        }
    }

    private fun startTrackingLocation(lat: Double, long: Double) {
        // If this is the first location or a new location, start tracking time
        if (lastLocation == null || lastLocation != Pair(lat, long)) {
            // If user moved from a previous location, calculate time spent there
            lastLocation?.let {
                val timeSpent = SystemClock.elapsedRealtime() - locationStartTime
                Log.d("LocationService", "Time spent in last location (${it.first}, ${it.second}): ${timeSpent / 1000} seconds")
                
                // Send time spent in the last location to the callback
                locationCallback?.onLocationUpdated(it.first, it.second, timeSpent / 1000)
            }

            // Update to the new location and reset the start time
            lastLocation = Pair(lat, long)
            locationStartTime = SystemClock.elapsedRealtime()
        }
    }

    private fun start() {
        if (isTrackingActive) return
        
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE // Or use FLAG_MUTABLE if you need to mutate the PendingIntent later
        )

        val notification = NotificationCompat.Builder(this, "location_channel")
            .setContentTitle("App Running")
            .setContentText("")
            .setSmallIcon(R.drawable.ic_launcher_background) // Ensure this is a valid drawable resource
            .setContentIntent(pendingIntent) // Set the pending intent
            .setOngoing(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        locationClient
            .getLocationUpdates(30000L)
            .catch { e -> e.printStackTrace() }
            .onEach { location ->
                // Process all location updates regardless of time
                val lat = location.latitude
                val long = location.longitude
                startTrackingLocation(lat, long)
                locationCallback?.onLocationUpdated(lat, long, 0)
                val updatedNotification = notification.setContentText(
                    ""
                )
                notificationManager.notify(1, updatedNotification.build())
            }
            .launchIn(serviceScope)

        startForeground(1, notification.build())
        isTrackingActive = true
    }

    private fun stop() {
        if (!isTrackingActive) return
        
        // Save the last location time data before stopping
        lastLocation?.let {
            val timeSpent = SystemClock.elapsedRealtime() - locationStartTime
            Log.d("LocationService", "Final time spent in location (${it.first}, ${it.second}): ${timeSpent / 1000} seconds")
            locationCallback?.onLocationUpdated(it.first, it.second, timeSpent / 1000)
        }
        
        stopForeground(true)
        isTrackingActive = false
        
        // Don't stopSelf() here if you want the service to remain running
        // Schedule to start at next business hours instead
        scheduleNextBusinessHoursAction(true)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // This will be called when the app is swiped away from recent apps
        // Send a broadcast to restart the service
        val broadcastIntent = Intent(this, RestartServiceReceiver::class.java)
        broadcastIntent.action = "android.intent.action.RESTART_SERVICE"
        sendBroadcast(broadcastIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        val broadcastIntent = Intent(this, RestartServiceReceiver::class.java)
        broadcastIntent.action = Intent.ACTION_BOOT_COMPLETED
        sendBroadcast(broadcastIntent)
    }

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
    }
}

