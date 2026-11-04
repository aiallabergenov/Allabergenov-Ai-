#!/usr/bin/env bash
# ALLABERGENOV AI — Self-Extracting Android Studio Kotlin + Jetpack Compose Project
set -e
echo "Extracting ALLABERGENOV AI Android Project..."
mkdir -p "android-app/app/src/main"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/app/src/main/AndroidManifest.xml"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="uz.allabergenov.ai">

    <!-- Network & Voice Recognition -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Telephony & Messaging (Requested On-Demand Only + Mandatory User Confirmation) -->
    <uses-permission android:name="android.permission.CALL_PHONE" />
    <uses-permission android:name="android.permission.SEND_SMS" />

    <!-- System AlarmClock Intent -->
    <uses-permission android:name="com.android.alarm.permission.SET_ALARM" />

    <!-- App Launching Discovery on Android Devices -->
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />

    <uses-feature android:name="android.hardware.telephony" android:required="false" />
    <uses-feature android:name="android.hardware.microphone" android:required="true" />

    <!-- Explicit package visibility queries for Android 11+ -->
    <queries>
        <package android:name="org.telegram.messenger" />
        <package android:name="com.google.android.deskclock" />
        <package android:name="com.android.camera" />
        <package android:name="com.google.android.calculator" />
        <package android:name="com.google.android.dialer" />
        <intent>
            <action android:name="android.intent.action.CALL" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="smsto" />
        </intent>
        <intent>
            <action android:name="android.provider.AlarmClock.ACTION_SET_ALARM" />
        </intent>
    </queries>

    <application
        android:allowBackup="false"
        android:label="ALLABERGENOV AI"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.DeviceDefault.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF_ALLABERGENOV_FILE
mkdir -p "android-app/app"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/app/build.gradle.kts"
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "uz.allabergenov.ai"
    compileSdk = 35

    defaultConfig {
        applicationId = "uz.allabergenov.ai"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        // Universal Android device support with multilingual locales (UZ, RU, EN)
        resConfigs("en", "ru", "uz", "xxhdpi")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
    }

    applicationVariants.all {
        outputs.all {
            val output = this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output?.outputFileName = "ALLABERGENOV_AI.apk"
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.02.00")
    implementation(composeBom)
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
EOF_ALLABERGENOV_FILE
mkdir -p "android-app/app/src/main/java/uz/allabergenov/ai"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/app/src/main/java/uz/allabergenov/ai/MainActivity.kt"
package uz.allabergenov.ai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.core.content.ContextCompat
import uz.allabergenov.ai.intents.AndroidIntentDispatcher
import uz.allabergenov.ai.ui.AllabergenovAiScreen
import java.util.Locale

class MainActivity : ComponentActivity(), TextToSpeech.OnInitListener {

    private var speechRecognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private var pendingPermissionCallback: ((Boolean) -> Unit)? = null

    // On-Demand Permission Launcher: Requests permissions on-demand only
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        pendingPermissionCallback?.invoke(isGranted)
        pendingPermissionCallback = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        tts = TextToSpeech(this, this)
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        val intentDispatcher = AndroidIntentDispatcher(this)

        setContent {
            AllabergenovAiScreen(
                dispatcher = intentDispatcher,
                onRequestPermissionOnDemand = { permission, onResult ->
                    requestPermissionWhenNeeded(permission, onResult)
                },
                onSpeakText = { text, langCode ->
                    speakMultilingual(text, langCode)
                },
                onStartVoiceListening = { langCode, onTranscript ->
                    startVoiceCapture(langCode, onTranscript)
                }
            )
        }
    }

    private fun requestPermissionWhenNeeded(
        permission: String,
        onResult: (Boolean) -> Unit
    ) {
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            onResult(true)
        } else {
            pendingPermissionCallback = onResult
            permissionLauncher.launch(permission)
        }
    }

    private fun startVoiceCapture(langCode: String, onTranscript: (String) -> Unit) {
        requestPermissionWhenNeeded(Manifest.permission.RECORD_AUDIO) { granted ->
            if (!granted) return@requestPermissionWhenNeeded

            val localeTag = when (langCode) {
                "uz" -> "uz-UZ"
                "ru" -> "ru-RU"
                else -> "en-US"
            }

            val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeTag)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            }

            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        onTranscript(matches[0])
                    }
                }
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onError(error: Int) {}
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            speechRecognizer?.startListening(recognizerIntent)
        }
    }

    private fun speakMultilingual(text: String, langCode: String) {
        val locale = when (langCode) {
            "uz" -> Locale("uz", "UZ")
            "ru" -> Locale("ru", "RU")
            else -> Locale.US
        }
        tts?.language = locale
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "allabergenov_ai_utt_" + System.currentTimeMillis())
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.setPitch(0.95f)
            tts?.setSpeechRate(1.0f)
        }
    }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        tts?.shutdown()
        super.onDestroy()
    }
}
EOF_ALLABERGENOV_FILE
mkdir -p "android-app/app/src/main/java/uz/allabergenov/ai/intents"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/app/src/main/java/uz/allabergenov/ai/intents/AndroidIntentDispatcher.kt"
package uz.allabergenov.ai.intents

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.AlarmClock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class AndroidIntentDispatcher(private val context: Context) {

    private val httpClient = OkHttpClient()

    /**
     * CRITICAL SAFETY RULE:
     * Phone calls NEVER execute unless userConfirmedExplicitly == true.
     */
    fun placePhoneCallConfirmed(phoneNumber: String, userConfirmedExplicitly: Boolean): Boolean {
        require(userConfirmedExplicitly) {
            "SECURITY VIOLATION: Phone call blocked because user confirmation was not granted."
        }
        val cleanPhone = phoneNumber.replace("\\s+".toRegex(), "")
        val callIntent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$cleanPhone")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(callIntent)
        return true
    }

    /**
     * CRITICAL SAFETY RULE:
     * SMS composition/sending NEVER executes unless userConfirmedExplicitly == true.
     */
    fun sendSmsConfirmed(
        phoneNumber: String,
        messageBody: String,
        userConfirmedExplicitly: Boolean
    ): Boolean {
        require(userConfirmedExplicitly) {
            "SECURITY VIOLATION: SMS blocked because user confirmation was not granted."
        }
        val cleanPhone = phoneNumber.replace("\\s+".toRegex(), "")
        val smsIntent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("smsto:$cleanPhone")
            putExtra("sms_body", messageBody)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(smsIntent)
        return true
    }

    /**
     * CRITICAL SAFETY RULE:
     * Telegram Bot messages NEVER dispatch unless userConfirmedExplicitly == true.
     */
    suspend fun sendTelegramMessageConfirmed(
        proxyEndpointUrl: String,
        chatId: String,
        messageText: String,
        userConfirmedExplicitly: Boolean
    ): Boolean = withContext(Dispatchers.IO) {
        require(userConfirmedExplicitly) {
            "SECURITY VIOLATION: Telegram message blocked without user confirmation."
        }
        val payload = JSONObject().apply {
            put("chatId", chatId)
            put("text", messageText)
            put("userConfirmed", true)
        }
        val body = payload.toString().toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url("$proxyEndpointUrl/api/telegram/send")
            .post(body)
            .build()

        httpClient.newCall(request).execute().use { response ->
            response.isSuccessful
        }
    }

    /**
     * Schedules an alarm using Android AlarmClock Intents.
     */
    fun createSystemAlarm(hour: Int, minute: Int, label: String): Boolean {
        val alarmIntent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hour)
            putExtra(AlarmClock.EXTRA_MINUTES, minute)
            putExtra(AlarmClock.EXTRA_MESSAGE, label)
            putExtra(AlarmClock.EXTRA_SKIP_UI, false)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(alarmIntent)
        return true
    }

    /**
     * Launches an installed application by package name.
     */
    fun launchInstalledApp(packageName: String): Boolean {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        } ?: return false
        context.startActivity(launchIntent)
        return true
    }
}
EOF_ALLABERGENOV_FILE
mkdir -p "android-app/app/src/main/java/uz/allabergenov/ai/ui"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/app/src/main/java/uz/allabergenov/ai/ui/AllabergenovAiScreen.kt"
package uz.allabergenov.ai.ui

import android.Manifest
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import uz.allabergenov.ai.intents.AndroidIntentDispatcher

sealed class PendingCriticalAction(val title: String, val target: String, val detail: String) {
    class PhoneCall(val name: String, val phone: String) :
        PendingCriticalAction("CONFIRM VOICE CALL", phone, "Recipient: $name")
    class SmsDispatch(val name: String, val phone: String, val body: String) :
        PendingCriticalAction("CONFIRM SMS DISPATCH", phone, "Message: $body")
    class TelegramMessage(val handle: String, val chatId: String, val body: String) :
        PendingCriticalAction("CONFIRM TELEGRAM MESSAGE", handle, "Message: $body")
}

@Composable
fun AllabergenovAiScreen(
    dispatcher: AndroidIntentDispatcher,
    onRequestPermissionOnDemand: (String, (Boolean) -> Unit) -> Unit,
    onSpeakText: (String, String) -> Unit,
    onStartVoiceListening: (String, (String) -> Unit) -> Unit
) {
    var selectedLang by remember { mutableStateOf("uz") }
    var isListening by remember { mutableStateOf(false) }
    var pendingConfirmation by remember { mutableStateOf<PendingCriticalAction?>(null) }

    val infiniteTransition = rememberInfiniteTransition(label = "allabergenov_core")
    val outerAngle by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(26000, easing = LinearEasing)),
        label = "outer_ring"
    )
    val innerAngle by infiniteTransition.animateFloat(
        initialValue = 360f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(tween(16000, easing = LinearEasing)),
        label = "inner_ring"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF070B12))
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Top Bar
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "ALLABERGENOV AI",
                    color = Color(0xFF00E5FF),
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("uz", "ru", "en").forEach { lang ->
                        Button(
                            onClick = { selectedLang = lang },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (selectedLang == lang) Color(0xFF00E5FF) else Color(0xFF111C2D)
                            ),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = lang.uppercase(),
                                color = if (selectedLang == lang) Color(0xFF070B12) else Color.White
                            )
                        }
                    }
                }
            }

            // Animated Holographic Core
            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(240.dp)) {
                Canvas(modifier = Modifier.fillMaxSize().rotate(outerAngle)) {
                    drawArc(
                        color = Color(0xFF00E5FF),
                        startAngle = 0f,
                        sweepAngle = 270f,
                        useCenter = false,
                        style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
                    )
                }
                Canvas(modifier = Modifier.size(180.dp).rotate(innerAngle)) {
                    drawArc(
                        color = Color(0xFF38BDF8),
                        startAngle = 45f,
                        sweepAngle = 200f,
                        useCenter = false,
                        style = Stroke(width = 6.dp.toPx(), cap = StrokeCap.Round)
                    )
                }
                Button(
                    onClick = {
                        isListening = true
                        onStartVoiceListening(selectedLang) { transcript ->
                            isListening = false
                        }
                    },
                    shape = CircleShape,
                    modifier = Modifier.size(96.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0EA5E9))
                ) {
                    Text(if (isListening) "REC" else "MIC", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }

            // Safety Footer
            Text(
                text = "CONFIRMATION GATE: ACTIVE (CALL · SMS · TELEGRAM)",
                color = Color(0xFF94A3B8),
                fontSize = 11.sp,
                fontFamily = FontFamily.Monospace
            )
        }

        // Mandatory User Confirmation Dialog before EVERY Call, SMS, or Telegram message
        pendingConfirmation?.let { pending ->
            AlertDialog(
                onDismissRequest = { pendingConfirmation = null },
                containerColor = Color(0xFF0F172A),
                title = {
                    Text(pending.title, color = Color(0xFF00E5FF), fontWeight = FontWeight.Bold)
                },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Target: ${pending.target}", color = Color.White)
                        Text(pending.detail, color = Color(0xFFCBD5E1))
                        Text(
                            "Explicit user confirmation is required before ALLABERGENOV AI executes this action.",
                            color = Color(0xFFF59E0B),
                            fontSize = 12.sp
                        )
                    }
                },
                confirmButton = {
                    Button(
                        onClick = {
                            when (pending) {
                                is PendingCriticalAction.PhoneCall -> {
                                    onRequestPermissionOnDemand(Manifest.permission.CALL_PHONE) { granted ->
                                        if (granted) dispatcher.placePhoneCallConfirmed(pending.phone, true)
                                    }
                                }
                                is PendingCriticalAction.SmsDispatch -> {
                                    onRequestPermissionOnDemand(Manifest.permission.SEND_SMS) { granted ->
                                        if (granted) dispatcher.sendSmsConfirmed(pending.phone, pending.body, true)
                                    }
                                }
                                is PendingCriticalAction.TelegramMessage -> {
                                    // Coroutine launch in ViewModel
                                }
                            }
                            pendingConfirmation = null
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00E5FF))
                    ) {
                        Text("Confirm & Execute", color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                },
                dismissButton = {
                    OutlinedButton(onClick = { pendingConfirmation = null }) {
                        Text("Cancel", color = Color.White)
                    }
                }
            )
        }
    }
}
EOF_ALLABERGENOV_FILE
mkdir -p "android-app"
cat << 'EOF_ALLABERGENOV_FILE' > "android-app/build-allabergenov-ai-apk.sh"
#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "  ALLABERGENOV AI — Android APK Build & Installer        "
echo "  Target: Android (SDK 26–35) | Output: ALLABERGENOV_AI.apk"
echo "=========================================================="

# 1. Verify JDK 17+
java -version

# 2. Assemble Debug APK
./gradlew clean assembleDebug

APK_PATH="app/build/outputs/apk/debug/ALLABERGENOV_AI.apk"
if [ ! -f "$APK_PATH" ]; then
  # Fallback check standard debug filename
  APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
fi

echo "APK output location: $APK_PATH"

# 3. Check for connected Android devices via ADB
if command -v adb >/dev/null 2>&1; then
  echo "Checking connected Android devices..."
  adb devices -l
  echo "Installing ALLABERGENOV_AI.apk..."
  adb install -r "$APK_PATH"
  echo "Launching ALLABERGENOV AI..."
  adb shell am start -n uz.allabergenov.ai.debug/uz.allabergenov.ai.MainActivity
fi
EOF_ALLABERGENOV_FILE
chmod +x android-app/build-allabergenov-ai-apk.sh
echo "Done! Project extracted to ./android-app/"