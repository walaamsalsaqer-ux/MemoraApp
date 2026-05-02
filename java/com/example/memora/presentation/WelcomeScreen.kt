package com.example.memora.presentation

import com.example.memora.R

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.material3.Text
import androidx.compose.ui.unit.*

@Composable
fun WelcomeScreen(onNext: () -> Unit) {

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White),
        contentAlignment = Alignment.Center
    ) {

        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            //////////////////////////////////////////////////////
            // الشعار
            //////////////////////////////////////////////////////
            Image(
                painter = painterResource(id = R.drawable.memora_logo),
                contentDescription = null,
                modifier = Modifier.size(85.dp)
            )

            Spacer(modifier = Modifier.height(6.dp))

            //////////////////////////////////////////////////////
            // النص
            //////////////////////////////////////////////////////
            Text(
                text = "مرحباً، دع ميمورا تعتني بك",
                fontSize = 11.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            //////////////////////////////////////////////////////
            // الزر (واضح + ما ينقص)
            //////////////////////////////////////////////////////
            Box(
                modifier = Modifier
                    .width(95.dp)
                    .height(42.dp)
                    .background(
                        color = Color(0xFF6A1B9A),
                        shape = RoundedCornerShape(50)
                    )
                    .clickable { onNext() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "ابدأ",
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}