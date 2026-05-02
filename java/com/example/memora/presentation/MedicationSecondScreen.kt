package com.example.memora.presentation

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore

@Composable
fun MedicationSecondScreen(
    onDone: () -> Unit
) {

    val context = LocalContext.current

    val med = GlobalState.currentMed.value
    val imageUrl = GlobalState.medImage.value

    val timeText = remember(GlobalState.medTimeMillis.value) {
        if (GlobalState.medTimeMillis.value == 0L) "--:--"
        else android.text.format.DateFormat.format(
            "hh:mm a",
            GlobalState.medTimeMillis.value
        ).toString()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFFFBF7FF),
                        Color(0xFFF3E8FA)
                    )
                )
            )
            .padding(10.dp),
        contentAlignment = Alignment.Center
    ) {

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceEvenly
        ) {

            //////////////////////////////////////
            // ⏰ الوقت (FIX نهائي)
            //////////////////////////////////////
            Card(
                modifier = Modifier
                    .width(80.dp)
                    .height(28.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = timeText,
                        fontSize = 10.sp, // 👈 صغرناه
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF6A1B9A),
                        maxLines = 1
                    )
                }
            }

            //////////////////////////////////////
            // 🟣 العنوان
            //////////////////////////////////////
            Text(
                text = "تذكير ثاني",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )

            //////////////////////////////////////
            // 💊 الكرت
            //////////////////////////////////////
            Card(
                modifier = Modifier.fillMaxWidth(0.8f),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {

                Row(
                    modifier = Modifier.padding(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {

                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.White),
                        contentAlignment = Alignment.Center
                    ) {
                        if (imageUrl.isNotEmpty()) {
                            AsyncImage(
                                model = imageUrl,
                                contentDescription = null,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Fit
                            )
                        } else {
                            Text("دواء", fontSize = 8.sp)
                        }
                    }

                    Spacer(modifier = Modifier.width(6.dp))

                    Column {

                        Text(
                            text = if (med.isEmpty()) "حان وقت الدواء" else med,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "لم يتم أخذ الدواء",
                            fontSize = 8.sp,
                            color = Color(0xFF7B1FA2)
                        )
                    }
                }
            }

            //////////////////////////////////////
            // 🔥 زرين جنب بعض (مرتبين)
            //////////////////////////////////////
            Row(
                modifier = Modifier.fillMaxWidth(0.8f),
                horizontalArrangement = Arrangement.spacedBy(6.dp) // 👈 ترتيب أفضل
            ) {

                Button(
                    onClick = {

                        GlobalState.medTaken.value = true

                        val prefs = context.getSharedPreferences("memora", Context.MODE_PRIVATE)
                        val userId = prefs.getString("userId", null)

                        if (userId != null) {
                            FirebaseFirestore.getInstance()
                                .collection("users")
                                .document(userId)
                                .collection("watch_data")
                                .document("med_status")
                                .set(
                                    mapOf(
                                        "taken" to true,
                                        "medicine" to med,
                                        "time" to Timestamp.now()
                                    )
                                )
                        }

                        onDone()
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF8E24AA)
                    ),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier
                        .weight(1f)
                        .height(30.dp)
                ) {
                    Text(
                        text = "تم أخذه",
                        fontSize = 9.sp,
                        color = Color.White
                    )
                }

                OutlinedButton(
                    onClick = {
                        onDone()
                    },
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier
                        .weight(1f)
                        .height(30.dp)
                ) {
                    Text(
                        text = "سآخذه الآن",
                        fontSize = 9.sp
                    )
                }
            }
        }
    }
}