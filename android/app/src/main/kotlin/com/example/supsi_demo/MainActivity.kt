package com.example.supsi_demo


import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.*
import androidx.core.app.NotificationCompat

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

import eu.proxity.client.ProxityClient
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL_ID = "ProxityService"
    private val CHANNEL = "com.example.supsi/blescanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            // Note: this method is invoked on the main thread.
            // TODO
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        createNotificationChannel()
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, 0)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Proximity service")
            .setContentText("Finding beacons near you, dear")
            .setSmallIcon(R.drawable.icon_notificaion_center_wh)
            .setContentIntent(pendingIntent)
            .build()

        val apiKey = "ed49ba5d-851c-474c-80e4-ddeb8fa75091"
        val deviceId = UUID.randomUUID()
        ProxityClient.start(context, notification, apiKey, deviceId)
    }

    override fun onDestroy() {
        ProxityClient.stop(context)
        super.onDestroy()
    }

    private fun createNotificationChannel() {

        val serviceChannel = NotificationChannel(
            CHANNEL_ID,
            "Proxity Service Channel",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager!!.createNotificationChannel(serviceChannel)
    }
}
