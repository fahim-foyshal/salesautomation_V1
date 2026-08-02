package com.example.salesautomation_v4

import android.app.job.JobParameters
import android.app.job.JobService
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

class RestartJobService : JobService() {

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartJob(params: JobParameters?): Boolean {
        Log.d("RestartJobService", "Restarting location service from JobScheduler...")
        val serviceIntent = Intent(this, LocationService::class.java)
        serviceIntent.action = LocationService.ACTION_START
        startForegroundService(serviceIntent)
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean {
        return true
    }
}
