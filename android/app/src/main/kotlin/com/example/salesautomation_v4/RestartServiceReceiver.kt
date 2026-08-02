package com.example.salesautomation_v4

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

class RestartServiceReceiver : BroadcastReceiver() {
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("RestartServiceReceiver", "Received action: ${intent?.action}")
        
        // Handle various system events that might require service restart
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_REBOOT,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            "android.intent.action.RESTART_SERVICE" -> {
                context?.let {
                    val serviceIntent = Intent(it, LocationService::class.java)
                    serviceIntent.action = LocationService.ACTION_START
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        it.startForegroundService(serviceIntent)
                    } else {
                        it.startService(serviceIntent)
                    }
                    
                    // Also schedule the job for additional reliability
                    val jobScheduler = JobSchedulerHelper(it)
                    jobScheduler.scheduleJob()
                    
                    Log.d("RestartServiceReceiver", "Service restart initiated")
                }
            }
        }
    }
}
