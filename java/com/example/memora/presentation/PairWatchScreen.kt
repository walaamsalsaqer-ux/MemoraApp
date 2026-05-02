package com.example.memora.presentation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import androidx.compose.ui.platform.LocalContext
import android.content.Context
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore

// 🔥 عدلنا الـ import
import com.example.memora.presentation.ConnectionService

@Composable
fun PairWatchScreen(onNext: () -> Unit) {

    val context = LocalContext.current
    val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)

    val mainColor = Color(0xFF7B1FA2)

    var pairingCode by remember { mutableStateOf("") }
    var isPaired by remember { mutableStateOf(false) }

    val db = FirebaseFirestore.getInstance()

    //////////////////////////////////////////////////////
    // 🔥 توليد الكود (مرة وحدة فقط)
    //////////////////////////////////////////////////////
    LaunchedEffect(Unit) {

        val savedCode = prefs.getString("pair_code", null)

        if (savedCode == null) {

            val code = (100000..999999).random().toString()
            pairingCode = code

            prefs.edit().putString("pair_code", code).apply()

            db.collection("pairing_codes")
                .document(code)
                .set(
                    mapOf(
                        "paired" to false,
                        "createdAt" to System.currentTimeMillis()
                    )
                )

        } else {
            pairingCode = savedCode
        }
    }

    //////////////////////////////////////////////////////
    // 🔥 مراقبة الربط
    //////////////////////////////////////////////////////
    LaunchedEffect(pairingCode) {

        if (pairingCode.isEmpty()) return@LaunchedEffect

        db.collection("pairing_codes")
            .document(pairingCode)
            .addSnapshotListener { snapshot, error ->

                if (error != null) {
                    Log.e("PAIR", "error", error)
                    return@addSnapshotListener
                }

                val paired = snapshot?.getBoolean("paired") ?: false
                val userId = snapshot?.getString("userId") ?: ""

                if (paired && userId.isNotEmpty() && !isPaired) {

                    isPaired = true

                    //////////////////////////////////////////////////////
                    // 🔥 حفظ بيانات الربط
                    //////////////////////////////////////////////////////
                    prefs.edit()
                        .putBoolean("paired", true)
                        .putString("userId", userId)
                        .apply()

                    //////////////////////////////////////////////////////
                    // 🔥 تشغيل الاتصال مباشرة
                    //////////////////////////////////////////////////////
                    ConnectionService.start(context)

                    //////////////////////////////////////////////////////
                    // 🧹 حذف الكود (تم إصلاح الخطأ)
                    //////////////////////////////////////////////////////
                    snapshot?.reference?.delete()

                    //////////////////////////////////////////////////////
                    // 🚀 الانتقال
                    //////////////////////////////////////////////////////
                    onNext()
                }
            }
    }

    //////////////////////////////////////////////////////
    // UI (بدون تغيير تصميمك)
    //////////////////////////////////////////////////////
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ) {

        Box(
            modifier = Modifier
                .size(200.dp)
                .background(Color.White, RoundedCornerShape(100.dp)),
            contentAlignment = Alignment.Center
        ) {

            Column(horizontalAlignment = Alignment.CenterHorizontally) {

                Text(
                    "اربط الساعة",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    "أدخل هذا الكود في التطبيق",
                    fontSize = 10.sp,
                    color = Color.Gray
                )

                Spacer(modifier = Modifier.height(12.dp))

                Box(
                    modifier = Modifier
                        .width(120.dp)
                        .height(50.dp)
                        .background(mainColor, RoundedCornerShape(20.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        pairingCode,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}