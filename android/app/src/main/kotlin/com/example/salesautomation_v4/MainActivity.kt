package com.example.salesautomation_v4

// Update the imports section by adding these imports
import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.widget.Toast
// Add this import for AlertDialog
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import android.content.SharedPreferences

import android.app.AlertDialog
import android.content.DialogInterface


class MainActivity : FlutterFragmentActivity(), LocationCallback {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val BACKGROUND_LOCATION_REQUEST_CODE = 1002
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003
    }

    // Add this flag to track settings redirects
    private var isReturningFromSettings = false
    
    // Separate permissions for different Android versions
    private val FOREGROUND_PERMISSIONS = arrayOf(
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.ACCESS_FINE_LOCATION
    )

    private val NOTIFICATION_PERMISSION = arrayOf(
        Manifest.permission.POST_NOTIFICATIONS
    )

    private val databaseHelper: DatabaseHelper by lazy {
        DatabaseHelper(this)
    }

    private val networkEventChannel = "com.example.salesautomation_v4"
    private var attachEvent: EventChannel.EventSink? = null

    private var locationService: LocationService? = null
    private var isServiceBound = false
    private lateinit var sharedPreferences: SharedPreferences
    private var username: String = "default_username"

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationService.LocalBinder
            locationService = binder.getService()
            locationService?.setLocationCallback(this@MainActivity)
            isServiceBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            locationService = null
            isServiceBound = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    
        // Fetch the username once during onCreate
        fetchUsername()
    
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "location",
                "Location",
                NotificationManager.IMPORTANCE_LOW
            )
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    
        // Check if notifications are enabled for the app
        if (!areNotificationsEnabled()) {
            showNotificationPermissionDialog()
            return
        }
    
        // Start the permission request flow
        checkAndRequestPermissions()
    }

    private fun fetchUsername() {
        // Retrieve the username from the database and store it in a variable
        databaseHelper.getUsername()?.let {
            username = it
        }
    }

    private fun checkAndRequestPermissions() {
        when {
            // Check notification permission first (Android 13+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && 
            !isNotificationPermissionGranted() -> {
                requestNotificationPermission()
            }
            // Check foreground location permissions
            !areForegroundLocationPermissionsGranted() -> {
                requestForegroundLocationPermissions()
            }
            // Check background location permission (Android 10+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && 
            !isBackgroundLocationPermissionGranted() -> {
                requestBackgroundLocationPermission()
            }
            // All permissions granted
            else -> {
                checkLocationAndStartService()
            }
        }
    }

    private fun isNotificationPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Not required for older versions
        }
    }

    private fun areForegroundLocationPermissionsGranted(): Boolean {
        return FOREGROUND_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun isBackgroundLocationPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Not required for older versions
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                this,
                NOTIFICATION_PERMISSION,
                NOTIFICATION_PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun requestForegroundLocationPermissions() {
        ActivityCompat.requestPermissions(
            this,
            FOREGROUND_PERMISSIONS,
            PERMISSION_REQUEST_CODE
        )
    }

    private fun requestBackgroundLocationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ - Show explanation and redirect to settings
                showBackgroundLocationExplanationAndRedirect()
            } else {
                // Android 10 - Can request directly
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                    BACKGROUND_LOCATION_REQUEST_CODE
                )
            }
        }
    }

    private fun showBackgroundLocationExplanationAndRedirect() {
        Toast.makeText(
            this,
            "For continuous location tracking, please enable 'Allow all the time' in the next screen",
            Toast.LENGTH_LONG
        ).show()

        // Navigate to app-specific permission settings
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
    }

    private fun checkLocationAndStartService() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        if (isEnabled) {
            val serviceIntent = Intent(this, LocationService::class.java).apply {
                action = LocationService.ACTION_START
            }
            
            // Use startForegroundService for Android O and above
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            
            bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
            
            // Also schedule the job for additional reliability
            val jobScheduler = JobSchedulerHelper(this)
            jobScheduler.scheduleJob()
        } else {
            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            startActivity(intent)
            Toast.makeText(this@MainActivity, "Enable location", Toast.LENGTH_LONG).show()
        }
    }

    private fun areNotificationsEnabled(): Boolean {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // For Android 13+ (Tiramisu), check runtime permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } 
        // For Android 8.0+ (Oreo) to Android 12, check notification channel settings
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return notificationManager.areNotificationsEnabled()
        }
        // For older versions
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            NOTIFICATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Notification permission granted, continue with location permissions
                    checkAndRequestPermissions()
                } else {
                    // Permission denied, show dialog to redirect to settings
                    showNotificationPermissionDialog()
                }
            }
            
            PERMISSION_REQUEST_CODE -> {
                val permissionsGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                if (permissionsGranted) {
                    // Foreground permissions granted, check background permission
                    checkAndRequestPermissions()
                } else {
                    Toast.makeText(this, "Location permissions are required", Toast.LENGTH_LONG).show()
                    finishAffinity()
                }
            }
            
            BACKGROUND_LOCATION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Background permission granted
                    checkLocationAndStartService()
                } else {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        // For Android 11+, redirect to settings
                        showBackgroundLocationExplanationAndRedirect()
                    } else {
                        Toast.makeText(this, "Background location permission denied", Toast.LENGTH_LONG).show()
                        // You might want to continue anyway or show a different message
                        checkLocationAndStartService()
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        
        // Only process permission checks if returning from settings
        if (isReturningFromSettings) {
            isReturningFromSettings = false
            
            // Check all permissions in sequence without redirecting multiple times
            when {
                !areNotificationsEnabled() -> {
                    // Still need notification permission
                    showNotificationPermissionDialog()
                    return
                }
                !areForegroundLocationPermissionsGranted() -> {
                    // Still need foreground location
                    Toast.makeText(this, "Location permissions are required", Toast.LENGTH_LONG).show()
                    requestForegroundLocationPermissions()
                    return
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !isBackgroundLocationPermissionGranted() -> {
                    // Still need background location
                    requestBackgroundLocationPermission()
                    return
                }
                else -> {
                    // All permissions granted
                    checkLocationAndStartService()
                }
            }
        }
    }

    private fun showNotificationPermissionDialog() {
        AlertDialog.Builder(this)
            .setTitle("Notification Permission Required")
            .setMessage("This app requires notification permission to work properly. Please enable it in the settings.")
            .setPositiveButton("Open Settings") { dialog: DialogInterface, _: Int ->
                openNotificationSettings()
            }
            .setNegativeButton("Exit App") { dialog: DialogInterface, _: Int ->
                finishAffinity()
            }
            .setCancelable(false)
            .show()
    }

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                    action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
                else -> {
                    action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    data = Uri.fromParts("package", packageName, null)
                }
            }
        }
        startActivity(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, networkEventChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink) {
                    Log.w("TAG_NAME", "Adding listener")
                    attachEvent = events
                }

                override fun onCancel(args: Any?) {
                    Log.w("TAG_NAME", "Cancelling listener")
                    attachEvent = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "locationPlatform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocation" -> {
                        checkAndRequestPermissions()
                    }
                    "stopLocation" -> {
                        Intent(applicationContext, LocationService::class.java).apply {
                            action = LocationService.ACTION_STOP
                        }.also { intent ->
                            startService(intent)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun onLocationUpdated(latitude: Double, longitude: Double, staymint: Long) {
        if (username == "default_username") {
            Log.i("LocationUpdate", "Skipping location update for default user")
            return
        }
        
        // Prepare the data to send
        val client = OkHttpClient()

        val apiUrl = "https://erp.hishab.me/app/mobile/EmployeePortal/auth/data_push.php"

        // Create the JSON data
        val jsonData = JSONArray().apply {
            put(
                JSONObject().apply {
                    put("latitude", latitude)
                    put("longitude", longitude)
                    put("user_id", username)
                    put("staytime", staymint)
                }
            )
        }
        Log.i("LocationData", "Sending Location Data: $jsonData")
        val mediaType = "application/json".toMediaTypeOrNull()
        val requestBody = jsonData.toString().toRequestBody(mediaType)

        val request = Request.Builder()
            .url(apiUrl)
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: IOException) {
                Log.e("LocationUpdate", "Error sending location data: ${e.message}")
            }

            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                    val responseBody = response.body?.string()
                if (response.isSuccessful) {
                    Log.i("LocationUpdate", "Response: $responseBody")
                    Log.i("LocationUpdate", "Location data sent successfully")
                } else {
                    Log.e("LocationUpdate", "Failed to send data. Status code: ${response.code}")
                }
            }
        })

        // Send location to Flutter
        runOnUiThread {
            attachEvent?.success("$latitude, $longitude")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }
}