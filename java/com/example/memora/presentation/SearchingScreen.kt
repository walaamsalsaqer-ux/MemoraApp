package com.example.memora.presentation

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.*
import com.example.memora.R
import kotlinx.coroutines.delay

@Composable
fun SearchingScreen(onNext: () -> Unit) {

    val infiniteTransition = rememberInfiniteTransition()

    val widthAnim by infiniteTransition.animateFloat(
        initialValue = 10f,
        targetValue = 60f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        )
    )

    LaunchedEffect(Unit) {
        delay(2000)
        onNext()
    }

    Box(
        modifier = Modifier.fillMaxSize().background(Color.White),
        contentAlignment = Alignment.Center
    ) {

        Column(horizontalAlignment = Alignment.CenterHorizontally) {

            CircularProgressIndicator(color = Color(0xFF7B1FA2))

            Spacer(modifier = Modifier.height(16.dp))

            //////////////////////////////////////
            // حركة الربط
            //////////////////////////////////////
            Row(verticalAlignment = Alignment.CenterVertically) {

                Image(
                    painter = painterResource(id = R.drawable.phone),
                    contentDescription = null,
                    modifier = Modifier.size(22.dp)
                )

                Spacer(modifier = Modifier.width(6.dp))

                Box(
                    modifier = Modifier
                        .width(widthAnim.dp)
                        .height(2.dp)
                        .background(Color(0xFF7B1FA2))
                )

                Spacer(modifier = Modifier.width(6.dp))

                Image(
                    painter = painterResource(id = R.drawable.watch),
                    contentDescription = null,
                    modifier = Modifier.size(22.dp)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text("جاري الاتصال...", fontSize = 12.sp)
        }
    }
}