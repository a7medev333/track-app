package com.example.app;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.work.Constraints;
import androidx.work.NetworkType;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.app/background_service";
    private static final String WORK_TAG = "locationUpdateWork";
    private static final int PERMISSION_REQUEST_CODE = 123;
    private MethodChannel.Result pendingResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "startLocationService":
                        pendingResult = result;
                        checkAndRequestPermissions();
                        break;
                    case "stopLocationService":
                        stopLocationService();
                        result.success(true);
                        break;
                    case "isServiceRunning":
                        result.success(LocationService.isRunning());
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            });
    }

    private void checkAndRequestPermissions() {
        List<String> permissions = new ArrayList<>();
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS);
            }
        }

        if (!permissions.isEmpty()) {
            ActivityCompat.requestPermissions(this,
                    permissions.toArray(new String[0]),
                    PERMISSION_REQUEST_CODE);
        } else {
            startLocationService();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                         @NonNull int[] grantResults) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            
            if (allGranted) {
                startLocationService();
            } else {
                if (pendingResult != null) {
                    pendingResult.error("PERMISSION_DENIED",
                            "Required permissions were not granted", null);
                    pendingResult = null;
                }
            }
        }
    }

    private void startLocationService() {
        // Start foreground service
        Intent serviceIntent = new Intent(this, LocationService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }

        // Configure WorkManager
        Constraints constraints = new Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build();

        PeriodicWorkRequest locationWorkRequest =
            new PeriodicWorkRequest.Builder(LocationWorkManager.class, 2, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .addTag(WORK_TAG)
                .build();

        WorkManager.getInstance(getApplicationContext())
            .enqueue(locationWorkRequest);

        NotificationService.showNotification(
            this,
            "Location Service Started",
            "The location service has been started and will run in the background."
        );

        if (pendingResult != null) {
            pendingResult.success(true);
            pendingResult = null;
        }
    }

    private void stopLocationService() {
        // Stop foreground service
        Intent serviceIntent = new Intent(this, LocationService.class);
        serviceIntent.setAction("STOP_SERVICE");
        startService(serviceIntent);

        // Cancel WorkManager tasks
        WorkManager.getInstance(getApplicationContext())
            .cancelAllWorkByTag(WORK_TAG);

        NotificationService.showNotification(
            this,
            "Location Service Stopped",
            "The location service has been stopped."
        );
    }
}
