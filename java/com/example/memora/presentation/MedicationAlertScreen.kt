package com.example.memora.presentation

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun MedicationAlertScreen(
    onDone: () -> Unit
) {
    val context = LocalContext.current

    val med = GlobalState.currentMed.value
    val imageUrl = GlobalState.medImage.value
    val audioUrl = GlobalState.medAudio.value

    //////////////////////////////////////
    // ⏰ الوقت (FIX)
    //////////////////////////////////////
    val time = remember(GlobalState.medTimeMillis.value) {
        if (GlobalState.medTimeMillis.value == 0L) {
            "--:--"
        } else {
            SimpleDateFormat("hh:mm a", Locale.getDefault())
                .format(Date(GlobalState.medTimeMillis.value))
        }
    }

    //////////////////////////////////////
    // 🔊 الصوت
    //////////////////////////////////////
    var mediaPlayer by remember { mutableStateOf<MediaPlayer?>(null) }

    fun stopAudio() {
        try { mediaPlayer?.stop() } catch (_: Exception) {}
        try { mediaPlayer?.release() } catch (_: Exception) {}
        mediaPlayer = null
    }

    LaunchedEffect(audioUrl) {

        if (audioUrl.isEmpty()) return@LaunchedEffect

        stopAudio()

        Thread {
            try {
                val player = MediaPlayer()

                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )

                player.setDataSource(audioUrl)
                player.prepare() // 👈 أسرع من async
                player.isLooping = true
                player.start()

                mediaPlayer = player

            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.start()

        //////////////////////////////////////
        // 🔔 اهتزاز
        //////////////////////////////////////
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(
                    longArrayOf(0, 300, 200, 300),
                    -1
                )
            )
        } else {
            vibrator.vibrate(800)
        }
    }

    DisposableEffect(Unit) {
        onDispose { stopAudio() }
    }

    //////////////////////////////////////
    // 🎨 UI (نفس تصميمك)
    //////////////////////////////////////
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
            .padding(horizontal = 16.dp, vertical = 12.dp),
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
                        text = time,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF6A1B9A),
                        maxLines = 1
                    )
                }
            }

            //////////////////////////////////////
            // العنوان
            //////////////////////////////////////
            Text(
                text = "تذكير الدواء",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )

            //////////////////////////////////////
            // الكرت
            //////////////////////////////////////
            Card(
                modifier = Modifier.fillMaxWidth(0.9f),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {

                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(12.dp))
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
                            Text("دواء", fontSize = 9.sp)
                        }
                    }

                    Spacer(modifier = Modifier.width(6.dp))

                    Column {

                        Text(
                            text = if (med.isEmpty()) "حان وقت الدواء" else med,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "حان وقت الدواء",
                            fontSize = 9.sp,
                            color = Color(0xFF7B1FA2)
                        )
                    }
                }
            }

            //////////////////////////////////////
            // الزر
            //////////////////////////////////////
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

                    stopAudio()
                    onDone()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF8E24AA)
                ),
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier
                    .fillMaxWidth(0.85f)
                    .height(36.dp)
            ) {

                Text(
                    text = "تم أخذ الدواء",
                    color = Color.White,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}