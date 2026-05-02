package com.example.memora.presentation

import android.content.Context
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext

@Composable
fun AppNavigator() {

    val context = LocalContext.current
    val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)
    val userId = prefs.getString("userId", null)

    //////////////////////////////////////
    // 🔥 دخول مباشر للهوم
    //////////////////////////////////////
    LaunchedEffect(userId) {
        if (userId != null && GlobalState.screen.value == "welcome") {
            GlobalState.screen.value = "home"
        }
    }

    //////////////////////////////////////
    // ✅ تشغيل الخدمات (💊 + 📍 + 🔗)
    //////////////////////////////////////
    LaunchedEffect(userId) {
        if (userId != null) {

            // 💊 التذكير
            MedicationService.start(context)

            // 📍 السيف زون
            SafeZoneService.start(context)

            // 🔗 الاتصال (🔥 هذا اللي كان ناقص)
            ConnectionService.start(context)
        }
    }

    //////////////////////////////////////
    // 🔥 قراءة الحالة الحالية
    //////////////////////////////////////
    val screen = GlobalState.screen.value

    when (screen) {

        //////////////////////////////////////
        // 🟣 البداية
        //////////////////////////////////////
        "welcome" -> WelcomeScreen {
            GlobalState.screen.value = "pair"
        }

        "pair" -> PairWatchScreen {
            GlobalState.screen.value = "search"
        }

        "search" -> SearchingScreen {
            GlobalState.screen.value = "paired"
        }

        "paired" -> PairingCompleteScreen {
            GlobalState.screen.value = "home"
        }

        //////////////////////////////////////
        // 🏠 الصفحة الرئيسية
        //////////////////////////////////////
        "home" -> HomeScreen()

        //////////////////////////////////////
        // 💊 تنبيه الدواء
        //////////////////////////////////////
        "med_alert" -> MedicationAlertScreen(
            onDone = {
                GlobalState.screen.value = "home"
            }
        )

        //////////////////////////////////////
        // 🔁 التذكير الثاني
        //////////////////////////////////////
        "second_alert" -> MedicationSecondScreen(
            onDone = {
                GlobalState.screen.value = "home"
            }
        )

        //////////////////////////////////////
        // 📍 Safe Zone
        //////////////////////////////////////
        "safe_alert" -> SafeZoneAlertScreen(
            onDone = {
                GlobalState.screen.value = "home"
            }
        )

        //////////////////////////////////////
        // 🚨 السقوط
        //////////////////////////////////////
        "fall_alert" -> FallDetectionScreen()

        //////////////////////////////////////
        // 📤 تم الإرسال
        //////////////////////////////////////
        "sent" -> AlertSentScreen {
            GlobalState.screen.value = "home"
        }

        //////////////////////////////////////
        // 🔁 fallback
        //////////////////////////////////////
        else -> HomeScreen()
    }
}