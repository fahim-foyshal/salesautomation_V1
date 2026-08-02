package com.example.salesautomation_v4

interface LocationCallback {
    fun onLocationUpdated(latitude: Double, longitude: Double, timeSpent: Long)
}
