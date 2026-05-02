package com.example.memora.presentation

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions

object ConnectionService {

    private val handler = Handler(Looper.getMainLooper())
    private var started = false

    fun start(context: Context) {

        if (started) return
        started = true

        Log.d("CONNECTION", "🚀 Connection Service Started")

        val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)
        val userId = prefs.getString("userId", null)

        if (userId == null) {
            Log.e("CONNECTION", "❌ userId is NULL")
            started = false
            return
        }

        val db = FirebaseFirestore.getInstance()

        //////////////////////////////////////
        // 🔥 تحديث كل 5 ثواني
        //////////////////////////////////////
        val runnable = object : Runnable {
            override fun run() {

                val data = mapOf(
                    "status" to "connected",
                    "connected" to true,
                    "lastSeen" to FieldValue.serverTimestamp(),
                    "battery" to 80, // تقدرين بعدين تربطينه فعلي
                    "deviceType" to "watch",
                    "model" to Build.MODEL
                )

                db.collection("users")
                    .document(userId)
                    .collection("devices")
                    .document("watch") // 🔥 أهم تعديل (ثابت)
                    .set(data, SetOptions.merge())
                    .addOnSuccessListener {
                        Log.d("CONNECTION", "✅ Updated")
                    }
                    .addOnFailureListener {
                        Log.e("CONNECTION", "❌ Failed", it)
                    }

                handler.postDelayed(this, 5000)
            }
        }

        handler.post(runnable)
    }
}