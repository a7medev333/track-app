package com.example.app;

import android.content.Context;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;
import androidx.work.Data;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Task;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import org.json.JSONObject;
import okhttp3.*;


public class LocationWorkManager extends Worker {
    private static final String API_URL = "https://deepskyblue-loris-536950.hostingersite.com/api/locations";
    private static final String TAG = "LocationWorkManager";
    private final FusedLocationProviderClient fusedLocationClient;
    private static final String TAG2 = "OkHttpApiClient";
    private static final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build();

    public LocationWorkManager(
            @NonNull Context context,
            @NonNull WorkerParameters params) {
        super(context, params);
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            // Check network connectivity first
            ConnectivityManager connectivityManager = (ConnectivityManager) getApplicationContext()
                    .getSystemService(Context.CONNECTIVITY_SERVICE);
            Network network = connectivityManager.getActiveNetwork();
            if (network == null) {
                Log.w(TAG, "No active network connection");
                return Result.retry();
            }

            NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(network);
            if (networkCapabilities == null || 
                !networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                Log.w(TAG, "No internet connectivity");
                return Result.retry();
            }

            CompletableFuture<Location> locationFuture = new CompletableFuture<>();
            CompletableFuture<String> ipFuture = new CompletableFuture<>();

            // Get location
            Task<Location> locationTask = fusedLocationClient.getLastLocation();
            locationTask.addOnSuccessListener(location -> {
                if (location != null) {
                    locationFuture.complete(location);
                } else {
                    locationFuture.completeExceptionally(new Exception("Location not available"));
                }
            }).addOnFailureListener(locationFuture::completeExceptionally);

            // Get IP address in background
            new Thread(() -> {
                try {
                    String ip = getPublicIpAddress();
                    ipFuture.complete(ip);
                } catch (Exception e) {
                    Log.e(TAG, "Error getting IP address: " + e.getMessage());
                    ipFuture.completeExceptionally(e);
                }
            }).start();

            // Wait for both operations with timeout
            Location location = locationFuture.get(30, TimeUnit.SECONDS);
            String ip = ipFuture.get(30, TimeUnit.SECONDS);

            // Create data object
            JSONObject data = new JSONObject();
            data.put("latitude", location.getLatitude());
            data.put("longitude", location.getLongitude());
            data.put("ip", ip);

            // Send data to server
            sendDataToServer(data);

            Log.i(TAG, "Work completed successfully");
            return Result.success();
        } catch (Exception e) {
            Log.e(TAG, "Work failed: " + e.getMessage());
            NotificationService.showNotification(
                getApplicationContext(),
                "Location Update",
                "Will retry in the next interval: " + e.getMessage()
            );
            return Result.retry();
        }
    }

    private String getPublicIpAddress() throws Exception {
        URL url = new URL("https://api.ipify.org?format=json");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream()))) {
            StringBuilder response = new StringBuilder();
            String line;

            while ((line = reader.readLine()) != null) {
                response.append(line);
            }

            JSONObject jsonResponse = new JSONObject(response.toString());
            return jsonResponse.getString("ip");
        } finally {
            conn.disconnect();
        }
    }



    private void sendDataToServer(JSONObject data) throws Exception {
        // Get the authentication token
        String token = getApplicationContext()
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.auth_token", null);

        if (token == null || token.isEmpty()) {
            Log.e(TAG, "Authentication token not found");
            throw new Exception("Authentication token not found");
        }

        Log.i(TAG, "------------------------");
        Log.d(TAG, "Sending data: " + data.toString());
        Log.d(TAG, "Token : " + token);


        MediaType JSON = MediaType.get("application/json; charset=utf-8");
        RequestBody body = RequestBody.create(data.toString(), JSON);

        Request request = new Request.Builder()
                .url(API_URL)
                .post(body)
                .addHeader("Authorization", "Bearer " + token)
                .build();

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "";
            if (!response.isSuccessful()) {
                String errorMsg = "HTTP Error: " + response.code() + " | Response: " + responseBody;
                Log.e(TAG, errorMsg);
                throw new Exception(errorMsg);
            }
            Log.i(TAG2, "Response: " + responseBody);
        }

        Log.i(TAG, "------------------------");



        // URL url = new URL(API_URL);
        // HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        // try {
        //     conn.setRequestMethod("POST");
        //     conn.setRequestProperty("Content-Type", "application/json");
        //     conn.setRequestProperty("Authorization", "Bearer " + token);
        //     conn.setDoOutput(true);
        //     conn.setConnectTimeout(30000);
        //     conn.setReadTimeout(30000);

        //     try (OutputStream os = conn.getOutputStream()) {
        //         byte[] input = data.toString().getBytes(StandardCharsets.UTF_8);
        //         os.write(input, 0, input.length);
        //     }

        //     int responseCode = conn.getResponseCode();
        //     if (responseCode != HttpURLConnection.HTTP_OK) {
        //         String errorMessage = "Server returned code: " + responseCode;
        //         Log.e(TAG, errorMessage);
        //         throw new Exception(errorMessage);
        //     }

        //     try (BufferedReader br = new BufferedReader(
        //             new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
        //         StringBuilder response = new StringBuilder();
        //         String responseLine;
        //         while ((responseLine = br.readLine()) != null) {
        //             response.append(responseLine.trim());
        //         }
        //         Log.i(TAG, "Server response: " + response.toString());
        //     }
        // } finally {
        //     conn.disconnect();
        // }
    }
}
