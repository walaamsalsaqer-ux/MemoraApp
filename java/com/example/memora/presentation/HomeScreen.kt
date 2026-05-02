package com.example.memora.presentation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun HomeScreen() {

    val med = GlobalState.currentMed.value

    //////////////////////////////////////
    // 🔥 الوقت (FIX كامل)
    //////////////////////////////////////
    val timeText = remember(GlobalState.medTimeMillis.value) {
        if (GlobalState.medTimeMillis.value == 0L) {
            "--:--"
        } else {
            android.text.format.DateFormat.format(
                "hh:mm a",
                GlobalState.medTimeMillis.value
            ).toString()
        }
    }

    val inside = GlobalState.isInsideSafeZone.value
    val taken = GlobalState.medTaken.value
    val targetTime = GlobalState.medTimeMillis.value

    val primary = Color(0xFF7B1FA2)
    val bg = Color(0xFFF8F2FB)

    val success = Color(0xFF66BB6A)
    val danger = Color(0xFFEF5350)

    var remaining by remember { mutableStateOf("") }

    val hasMed = med.isNotEmpty() && targetTime != 0L

    //////////////////////////////////////
    // 🔥 العد التنازلي (FIX هنا فقط)
    //////////////////////////////////////
    LaunchedEffect(targetTime, taken) {

        if (!hasMed) {
            remaining = ""
            return@LaunchedEffect
        }

        while (true) {

            val now = System.currentTimeMillis()
            val diff = targetTime - now

            remaining = when {

                taken -> "تم أخذ الدواء ✅"

                diff > 60000 -> { // أكثر من دقيقة
                    val minutes = (diff / (1000 * 60)).toInt()
                    "بعد $minutes دقيقة"
                }

                diff in 1000..60000 -> { // أقل من دقيقة
                    val seconds = (diff / 1000).toInt()
                    "بعد $seconds ثانية"
                }

                diff in -60000..1000 -> { // حول وقت الدواء
                    "حان الآن"
                }

                else -> "فات الوقت ⏰"
            }

            delay(1000)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(bg)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {

        //////////////////////////////////////
        // 👋 Header
        //////////////////////////////////////
        Column(horizontalAlignment = Alignment.CenterHorizontally) {

            Text(
                text = "ميمورا",
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = primary
            )

            Text(
                text = "هنا لرعايتك",
                fontSize = 8.sp,
                color = Color.Gray
            )
        }

        //////////////////////////////////////
        // 💊 Medication Card
        //////////////////////////////////////
        Card(
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .weight(1f)
        ) {

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp),
                verticalArrangement = Arrangement.spacedBy(3.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {

                Text(
                    text = "الدواء القادم",
                    fontSize = 9.sp,
                    color = Color.Gray
                )

                if (hasMed) {

                    Text(
                        text = med,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = timeText,
                        color = primary,
                        fontSize = 11.sp
                    )

                    Text(
                        text = remaining,
                        fontSize = 8.sp,
                        color = when {
                            taken -> success
                            remaining == "حان الآن" -> primary
                            remaining.contains("فات") -> danger
                            else -> Color.Gray.copy(alpha = 0.6f)
                        }
                    )

                } else {
                    Text(
                        text = "لا يوجد تذكير",
                        fontSize = 11.sp,
                        color = Color.Gray
                    )
                }
            }
        }

        //////////////////////////////////////
        // 📍 Safe Zone Card
        //////////////////////////////////////
        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            modifier = Modifier
                .fillMaxWidth(0.85f)
                .weight(0.8f)
        ) {

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {

                Text(
                    text = "الموقع",
                    fontSize = 9.sp,
                    color = Color.Gray
                )

                Spacer(modifier = Modifier.height(3.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {

                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(
                                if (inside) success else danger,
                                CircleShape
                            )
                    )

                    Spacer(modifier = Modifier.width(6.dp))

                    Text(
                        text = if (inside) "داخل المنطقة الآمنة" else "خارج المنطقة",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}