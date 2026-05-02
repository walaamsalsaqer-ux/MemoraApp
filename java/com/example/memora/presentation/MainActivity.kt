package com.example.memora.presentation

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.memora.presentation.MedicationService

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = getSharedPreferences("memora", MODE_PRIVATE)
        val isPaired = prefs.getBoolean("paired", false)

        // 🔥 البداية
        GlobalState.screen.value =
            if (isPaired) "home" else "welcome"

        setContent {
            AppNavigator()
        }

        checkPermission()
    }

    private fun checkPermission() {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            startServices()
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                1001
            )
        }
    }

    private fun startServices() {

        val prefs = getSharedPreferences("memora", MODE_PRIVATE)

        val userId = prefs.getString("userId", null)

        // ❌ كان يمنع التشغيل
        // if (userId == null || !isPaired) return

        // ✅ الآن يسمح بالتجربة
        if (userId == null) return

        // 🔥 تشغيل كل السيرفسات
        SafeZoneService.start(this)
        MedicationService.start(this)
        ConnectionService.start(this)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        results: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, results)

        if (requestCode == 1001 &&
            results.isNotEmpty() &&
            results[0] == PackageManager.PERMISSION_GRANTED
        ) {
            startServices()
        }
    }
}