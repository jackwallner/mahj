package com.jackwallner.mahj.data

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.jackwallner.mahj.MahjApplication
import com.jackwallner.mahj.MainActivity
import com.jackwallner.mahj.R
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters

/**
 * Daily and weekly reminders on inexact repeating alarms. Exact alarms need a
 * Play declaration and a reminder a few minutes late costs nothing.
 */
class AlarmReminderScheduler(private val context: Context) : ReminderScheduler {
    private val alarms = context.getSystemService(AlarmManager::class.java)

    override fun scheduleDaily(hour: Int, minute: Int) {
        val now = LocalDateTime.now()
        var next = now.withHour(hour).withMinute(minute).withSecond(0).withNano(0)
        if (!next.isAfter(now)) next = next.plusDays(1)
        alarms.setInexactRepeating(AlarmManager.RTC_WAKEUP, next.millis(), AlarmManager.INTERVAL_DAY, pending(KIND_DAILY))
    }

    override fun cancelDaily() = alarms.cancel(pending(KIND_DAILY))

    override fun scheduleGameNight(day: DayOfWeek, hour: Int, minute: Int) {
        val now = LocalDateTime.now()
        var next = now.with(TemporalAdjusters.nextOrSame(day)).withHour(hour).withMinute(minute).withSecond(0).withNano(0)
        if (!next.isAfter(now)) next = next.plusWeeks(1)
        alarms.setInexactRepeating(AlarmManager.RTC_WAKEUP, next.millis(), AlarmManager.INTERVAL_DAY * 7, pending(KIND_GAME_NIGHT))
    }

    override fun cancelGameNight() = alarms.cancel(pending(KIND_GAME_NIGHT))

    private fun LocalDateTime.millis() = atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

    private fun pending(kind: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        kind.hashCode(),
        Intent(context, ReminderReceiver::class.java).putExtra(EXTRA_KIND, kind),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        const val EXTRA_KIND = "mahj.reminderKind"
        const val KIND_DAILY = "daily"
        const val KIND_GAME_NIGHT = "gameNight"
        const val CHANNEL_ID = "reminders"

        /** The notification route key the activity reads, as on iOS. */
        const val ROUTE_KEY = "mahj.route"
        const val GAME_NIGHT_PREP_VALUE = "game-night-prep"

        fun ensureChannel(context: Context) {
            val channel = NotificationChannel(CHANNEL_ID, "Practice reminders", NotificationManager.IMPORTANCE_DEFAULT)
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        fun canNotify(context: Context): Boolean =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!AlarmReminderScheduler.canNotify(context)) return
        AlarmReminderScheduler.ensureChannel(context)
        val gameNight = intent.getStringExtra(AlarmReminderScheduler.EXTRA_KIND) == AlarmReminderScheduler.KIND_GAME_NIGHT
        val open = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (gameNight) open.putExtra(AlarmReminderScheduler.ROUTE_KEY, AlarmReminderScheduler.GAME_NIGHT_PREP_VALUE)
        val content = PendingIntent.getActivity(
            context,
            if (gameNight) 2 else 1,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val (title, body) = if (gameNight) {
            "Your game night prep is ready" to "Five personalized minutes now can make the table feel calmer later."
        } else {
            "Time for a quick drill" to "Five minutes of practice keeps your Charleston calm and your rack reading sharp."
        }
        val notification = NotificationCompat.Builder(context, AlarmReminderScheduler.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(content)
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(if (gameNight) 2 else 1, notification)
        } catch (_: SecurityException) {
            // Permission revoked between the check and the post.
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        (context.applicationContext as? MahjApplication)?.graph?.settings?.rescheduleAll()
    }
}
