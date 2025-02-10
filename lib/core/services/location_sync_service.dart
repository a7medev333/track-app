// import 'package:app/core/config/token_storage.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:app/core/config/location_utils.dart';
// import 'package:app/core/config/network_utils.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:async';
// import 'package:app/core/services/notification_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       await BackgroundService.updateLocationAndIp();
//       return true;
//     } catch (e) {
//       print('Task execution failed: $e');
//       return false; // This will trigger a retry based on the backoff policy
//     }
//   });
// }

// class BackgroundService {
//   static const String taskKey = 'locationAndIpUpdate';
//   static const String apiEndpoint = 'http://192.168.242.92:8000/api/locations';
//   static bool _isInitialized = false;

//   static Future<void> initialize() async {
//     if (_isInitialized) return;
    
//     try {
//       print("Initializing background service...");
//       await NotificationService.initialize();
      
//       // Initialize Workmanager with custom configuration
//       await Workmanager().initialize(
//         callbackDispatcher,
//         isInDebugMode: true // Set to false in production
//       );
      
//       _isInitialized = true;
//       print("Background service initialized successfully");
//     } catch (e) {
//       print("Failed to initialize background service: $e");
//       rethrow;
//     }
//   }

//   static Future<void> startPeriodicTask() async {
//     try {
//       if (!_isInitialized) {
//         await initialize();
//       }

//       // Cancel any existing tasks before registering a new one
//       await Workmanager().cancelByUniqueName(taskKey);

//       print("Starting periodic task...");
//       await Workmanager().registerPeriodicTask(
//         taskKey,
//         taskKey,
//         frequency: Duration(minutes: 5),
//         initialDelay: Duration(seconds: 10),
//         constraints: Constraints(
//           networkType: NetworkType.connected,
//           requiresBatteryNotLow: true,
//         ),
//         backoffPolicy: BackoffPolicy.exponential,
//         backoffPolicyDelay: Duration(minutes: 1),
//         existingWorkPolicy: ExistingWorkPolicy.replace,
//       );
      
//       await NotificationService.showServiceRunningNotification();
//       print("Periodic task started successfully");
//     } catch (e) {
//       print("Failed to start periodic task: $e");
//       rethrow;
//     }
//   }

//   static Future<void> stopPeriodicTask() async {
//     try {
//       print("Stopping periodic task...");
//       // Cancel the task first
//       await Workmanager().cancelByUniqueName(taskKey);
//       // Then cancel the notification
//       await NotificationService.cancelServiceNotification();
//       print("Periodic task stopped successfully");
//     } catch (e) {
//       print("Failed to stop periodic task: $e");
//       rethrow;
//     }
//   }

//   static Future<void> updateLocationAndIp() async {
//     try {
//       print("Starting location and IP update...");
      
//       // Get token first to validate authentication
//       String? token = await TokenStorage.getToken();
//       if (token == null || token.isEmpty) {
//         print("No authentication token found. Stopping task.");
//         await stopPeriodicTask();
//         return;
//       }
      
//       // Check location
//       final position = await LocationService.getCurrentLocation();
//       if (position == null) {
//         print("Error: Could not get location. Please check location permissions and GPS status.");
//         await NotificationService.showLocationUpdateNotification(
//           "Failed to update location. Please check app permissions."
//         );
//         return;
//       }
      
//       // Check IP
//       final deviceIp = await DeviceConnection.getDeviceIp();
//       if (deviceIp.startsWith('Error:')) {
//         print("Error getting device IP: $deviceIp");
//         await NotificationService.showLocationUpdateNotification(
//           "Failed to get device IP. Please check network connection."
//         );
//         return;
//       }

//       print("----------------------------------------");
//       print('Location obtained - Lat: ${position.latitude}, Long: ${position.longitude}');
//       print('Device IP obtained: $deviceIp');
//       print("----------------------------------------");

//       // Attempt API call with timeout
//       print("Attempting to send data to server...");
//       final response = await http.post(
//         Uri.parse(apiEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token'
//         },
//         body: jsonEncode({
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'ip': deviceIp,
//         }),
//       ).timeout(
//         const Duration(seconds: 30),
//         onTimeout: () async {
//           await NotificationService.showLocationUpdateNotification(
//             "Request timed out. Will retry later."
//           );
//           throw TimeoutException('The request took too long to complete');
//         },
//       );

//       if (response.statusCode == 200) {
//         print("Successfully sent location and IP to server");
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('last_location_update', DateTime.now().toIso8601String());
        
//         await NotificationService.showLocationUpdateNotification(
//           "Location updated successfully"
//         );
//       } else if (response.statusCode == 401) {
//         print("Authentication failed. Stopping periodic task.");
//         await stopPeriodicTask();
//         await NotificationService.showLocationUpdateNotification(
//           "Authentication expired. Please log in again."
//         );
//       } else {
//         print("Server error: Status ${response.statusCode}");
//         print("Response body: ${response.body}");
//         await NotificationService.showLocationUpdateNotification(
//           "Failed to update location. Server error: ${response.statusCode}"
//         );
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       print('Background task error: $e');
//       print('Stack trace: $stackTrace');
//       await NotificationService.showLocationUpdateNotification(
//         "Error updating location: ${e.toString().split('\n')[0]}"
//       );
//       rethrow; // Let WorkManager know the task failed
//     }
//   }

//   static Future<bool> isServiceRunning() async {
//     try {
//       // This is a basic check. The actual task might have been killed by the system
//       final prefs = await SharedPreferences.getInstance();
//       final lastUpdate = prefs.getString('last_location_update');
//       if (lastUpdate == null) return false;
      
//       final lastUpdateTime = DateTime.parse(lastUpdate);
//       final now = DateTime.now();
      
//       // If last update was more than 10 minutes ago, consider service as not running
//       return now.difference(lastUpdateTime).inMinutes < 10;
//     } catch (e) {
//       print("Error checking service status: $e");
//       return false;
//     }
//   }
// }