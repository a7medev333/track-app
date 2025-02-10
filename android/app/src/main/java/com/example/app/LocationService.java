package com.example.app;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class LocationService extends Service {
    private static final int NOTIFICATION_ID = 1;
    private static boolean isServiceRunning = false;

    @Override
    public void onCreate() {
        super.onCreate();
        NotificationService.createNotificationChannel(this);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && "STOP_SERVICE".equals(intent.getAction())) {
            stopForeground(true);
            stopSelf();
            isServiceRunning = false;
            return START_NOT_STICKY;
        }

        if (!isServiceRunning) {
            isServiceRunning = true;
            startForegroundService();
        }

        return START_STICKY;
    }

    private void startForegroundService() {
        NotificationCompat.Builder notificationBuilder = 
            NotificationService.createServiceNotification(this);
        startForeground(NOTIFICATION_ID, notificationBuilder.build());
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isServiceRunning = false;
    }

    public static boolean isRunning() {
        return isServiceRunning;
    }
}
