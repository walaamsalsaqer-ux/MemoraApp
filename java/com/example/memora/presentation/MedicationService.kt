package com.example.memora.presentation

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore

object MedicationService {

    private var started = false

    private var alertShown = false
    private var secondAlertShown = false
    private var alertSentToMobile = false

    private var alertTime: Long = 0L
    private var medTimeMillis: Long = 0L
    private var lastAlertTime: Long = 0L

    private val handler = Handler(Looper.getMainLooper())

    fun start(context: Context) {

        if (started) {
            Log.d("MED", "⚠️ Already started")
            return
        }

        started = true
        Log.d("MED", "🚀 SERVICE STARTED")

        val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)
        val userId = prefs.getString("userId", null)

        if (userId == null) {
            Log.e("MED", "❌ userId is null")
            started = false
            return
        }

        val db = FirebaseFirestore.getInstance()

        //////////////////////////////////////
        // 💊 حالة أخذ الدواء
        //////////////////////////////////////
        db.collection("users")
            .document(userId)
            .collection("watch_data")
            .document("med_status")
            .addSnapshotListener { doc, error ->

                if (error != null) {
                    Log.e("MED", "❌ med_status error", error)
                    return@addSnapshotListener
                }

                val taken = doc?.getBoolean("taken") ?: false
                GlobalState.medTaken.value = taken
            }

        //////////////////////////////////////
        // 💊 قراءة الدواء
        //////////////////////////////////////
        db.collection("users")
            .document(userId)
            .collection("watch_data")
            .document("next_med")
            .addSnapshotListener { doc, error ->

                if (error != null) {
                    Log.e("MED", "❌ next_med error", error)
                    return@addSnapshotListener
                }

                if (doc == null || !doc.exists()) return@addSnapshotListener

                val name = doc.getString("name") ?: ""
                val image = doc.getString("imageUrl") ?: ""
                val audio = doc.getString("audioUrl") ?: ""
                val timestamp = doc.getTimestamp("time") ?: return@addSnapshotListener

                val newTime = timestamp.toDate().time

                //////////////////////////////////////
                // 🔁 إذا تغير الدواء
                //////////////////////////////////////
                if (GlobalState.currentMed.value != name || medTimeMillis != newTime) {

                    Log.d("MED", "🔄 New Medication Loaded")

                    alertShown = false
                    secondAlertShown = false
                    alertSentToMobile = false
                    alertTime = 0L
                    lastAlertTime = 0L

                    GlobalState.medTaken.value = false

                    db.collection("users")
                        .document(userId)
                        .collection("watch_data")
                        .document("med_status")
                        .set(
                            mapOf(
                                "taken" to false,
                                "medicine" to name,
                                "time" to timestamp
                            )
                        )
                }

                //////////////////////////////////////
                // ✅ تحديث القيم
                //////////////////////////////////////
                GlobalState.currentMed.value = name
                GlobalState.medImage.value = image
                GlobalState.medAudio.value = audio

                medTimeMillis = newTime
                GlobalState.medTimeMillis.value = medTimeMillis

                Log.d("MED", "📥 UPDATED: $name @ $medTimeMillis")
            }

        //////////////////////////////////////
        // ⏱ مراقبة الوقت
        //////////////////////////////////////
        handler.post(object : Runnable {
            override fun run() {

                try {

                    val now = System.currentTimeMillis()
                    val diff = now - medTimeMillis

                    //////////////////////////////////////
                    // 🔔 التنبيه الأول (نافذة 2 دقيقة)
                    //////////////////////////////////////
                    if (
                        !alertShown &&
                        !GlobalState.medTaken.value &&
                        medTimeMillis != 0L &&
                        diff in 0..(2 * 60 * 1000) &&
                        lastAlertTime != medTimeMillis
                    ) {

                        Log.d("MED", "🔔 FIRST ALERT")

                        alertShown = true
                        alertTime = now
                        lastAlertTime = medTimeMillis

                        GlobalState.screen.value = "med_alert"
                    }

                    //////////////////////////////////////
                    // 🔁 التذكير الثاني
                    //////////////////////////////////////
                    if (
                        alertShown &&
                        !secondAlertShown &&
                        !GlobalState.medTaken.value &&
                        alertTime != 0L
                    ) {

                        val passed = now - alertTime

                        if (passed >= 10 * 60 * 1000) {

                            Log.d("MED", "🔁 SECOND ALERT")

                            secondAlertShown = true
                            GlobalState.screen.value = "second_alert"
                        }
                    }

                    //////////////////////////////////////
                    // 📱 إرسال للجوال
                    //////////////////////////////////////
                    if (
                        alertShown &&
                        !GlobalState.medTaken.value &&
                        !alertSentToMobile &&
                        alertTime != 0L
                    ) {

                        val passed = now - alertTime

                        if (passed >= 15 * 60 * 1000) {

                            Log.d("MED", "📱 SEND ALERT TO MOBILE")

                            alertSentToMobile = true

                            db.collection("users")
                                .document(userId)
                                .collection("alerts")
                                .add(
                                    mapOf(
                                        "type" to "missed",
                                        "message" to "لم يتم أخذ الدواء",
                                        "medicine" to GlobalState.currentMed.value,
                                        "time" to Timestamp.now()
                                    )
                                )
                        }
                    }

                } catch (e: Exception) {
                    Log.e("MED", "❌ LOOP ERROR", e)
                }

                handler.postDelayed(this, 1000)
            }
        })
    }
}