package com.ridergroup.rider_group

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * Canaux des notifications push (D-68) :
     * - rider_sos : alertes SOS, importance maximale, son d'alarme ;
     * - rider_general : demandes, messages, balades, événements.
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val sos = NotificationChannel(
            "rider_sos",
            "Alertes SOS",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Un motard de votre balade a besoin d'aide"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 600, 300, 600, 300, 600)
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        val general = NotificationChannel(
            "rider_general",
            "Activité Rider Group",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Demandes, balades, événements, commentaires"
        }
        manager.createNotificationChannels(listOf(sos, general))
    }
}
