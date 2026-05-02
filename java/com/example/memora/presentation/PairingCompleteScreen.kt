package com.example.memora.presentation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.*

@Composable
fun PairingCompleteScreen(onNext: () -> Unit) {

    val mainColor = Color(0xFF7B1FA2)

    Box(
        modifier = Modifier.fillMaxSize().background(Color.White),
        contentAlignment = Alignment.Center
    ) {

        Column(horizontalAlignment = Alignment.CenterHorizontally) {

            Text("✓", fontSize = 42.sp, color = mainColor)

            Spacer(modifier = Modifier.height(12.dp))

            Text("تم الربط بنجاح", fontSize = 16.sp)

            Spacer(modifier = Modifier.height(20.dp))

            Button(
                onClick = onNext,
                colors = ButtonDefaults.buttonColors(containerColor = mainColor)
            ) {
                Text("ابدأ")
            }
        }
    }
}