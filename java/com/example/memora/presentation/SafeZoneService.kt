package com.example.memora.presentation

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration

object SafeZoneService {

    private var started = false
    private var alreadyOutside = false
    private var hasZone = false

    private var safeLat = 0.0
    private var safeLng = 0.0
    private var radius = 100.0
    private var isActive = false

    private var listener: ListenerRegistration? = null

    @SuppressLint("MissingPermission")
    fun start(context: Context) {

        if (started) return
        started = true

        val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)
        val userId = prefs.getString("userId", null) ?: return

        val db = FirebaseFirestore.getInstance()

        //////////////////////////////////////
        // 📍 قراءة السيف زون من فايربيس
        //////////////////////////////////////
        listener = db.collection("users")
            .document(userId)
            .collection("config")
            .document("safe_zone")
            .addSnapshotListener { snapshot, _ ->

                if (snapshot != null && snapshot.exists()) {

                    safeLat = snapshot.getDouble("lat") ?: 0.0
                    safeLng = snapshot.getDouble("lng") ?: 0.0
                    radius = snapshot.getDouble("radius") ?: 100.0
                    isActive = snapshot.getBoolean("isActive") ?: false

                    hasZone = true

                    Log.d("SAFE_ZONE", "📍 تم تحميل المنطقة")
                }
            }

        //////////////////////////////////////
        // 📡 تتبع الموقع
        //////////////////////////////////////
        val fused = LocationServices.getFusedLocationProviderClient(context)

        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            3000 // كل 3 ثواني
        ).build()

        fused.requestLocationUpdates(
            request,
            object : LocationCallback() {

                override fun onLocationResult(result: LocationResult) {

                    val location = result.lastLocation ?: return

                    if (!hasZone || !isActive) return

                    val distance = FloatArray(1)

                    Location.distanceBetween(
                        location.latitude,
                        location.longitude,
                        safeLat,
                        safeLng,
                        distance
                    )

                    val isOutside = distance[0] > radius

                    //////////////////////////////////////
                    // 🚨 خرج من المنطقة
                    //////////////////////////////////////
                    if (isOutside && !alreadyOutside) {

                        alreadyOutside = true

                        Log.d("SAFE_ZONE", "🚨 خارج المنطقة!")

                        GlobalState.isInsideSafeZone.value = false
                        GlobalState.screen.value = "safe_alert"
                    }

                    //////////////////////////////////////
                    // ✅ رجع للمنطقة
                    //////////////////////////////////////
                    if (!isOutside) {

                        alreadyOutside = false
                        GlobalState.isInsideSafeZone.value = true
                    }
                }
            },
            Looper.getMainLooper()
        )
    }

    //////////////////////////////////////
    // 🛑 إيقاف الخدمة
    //////////////////////////////////////
    fun stop() {
        started = false
        listener?.remove()
    }
}