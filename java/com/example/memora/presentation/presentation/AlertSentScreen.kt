package com.example.memora.presentation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.*
import kotlinx.coroutines.delay

@Composable
fun AlertSentScreen(
    onDone: () -> Unit
) {

    //////////////////////////////////////
    // 🔥 يرجع تلقائي بعد 3 ثواني
    //////////////////////////////////////
    LaunchedEffect(Unit) {
        delay(3000)
        onDone()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF2B2B2B)),
        contentAlignment = Alignment.Center
    ) {

        Box(
            modifier = Modifier
                .size(220.dp)
                .background(Color.White, shape = CircleShape)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {

            Column(horizontalAlignment = Alignment.CenterHorizontally) {

                Text("📤", fontSize = 22.sp)

                Spacer(modifier = Modifier.height(6.dp))

                Text("تم إرسال التنبيه", fontSize = 12.sp)

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    "سيتم إبلاغ المرافق",
                    fontSize = 10.sp
                )
            }
        }
    }
}