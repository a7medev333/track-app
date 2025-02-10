// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
//   static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     'location_service_channel',
//     'Location Service',
//     description: 'Notifications for location service updates',
//     importance: Importance.high,
//     enableVibration: true,
//   );

//   static Future<void> initialize() async {
//     try {
//       // Request permissions for iOS
//       await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );

//       const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//       const iosSettings = DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
    
//       const initializationSettings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );

//       final success = await _notifications.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: (details) {
//           if (kDebugMode) {
//             print('Notification clicked: ${details.payload}');
//           }
//         },
//       );

//       if (kDebugMode) {
//         print('Notifications initialized: $success');
//       }

//       final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//       await androidPlugin?.createNotificationChannel(_channel);

//     } catch (e) {
//       if (kDebugMode) {
//         print('Error initializing notifications: $e');
//       }
//     }
//   }

//   static Future<void> showServiceRunningNotification() async {
//     try {
//       const androidDetails = AndroidNotificationDetails(
//         'location_service_channel',
//         'Location Service',
//         channelDescription: 'Notifications for location service updates',
//         importance: Importance.high,
//         priority: Priority.high,
//         ongoing: true,
//         autoCancel: false,
//         styleInformation: BigTextStyleInformation(
//           'Location service is running in the background',
//           htmlFormatBigText: true,
//           contentTitle: '<b>Location Service Active</b>',
//           htmlFormatContentTitle: true,
//           summaryText: 'Tracking location updates',
//           htmlFormatSummaryText: true,
//         ),
//         category: AndroidNotificationCategory.service,
//         actions: <AndroidNotificationAction>[
//           AndroidNotificationAction(
//             'stop_service',
//             'Stop Service',
//             cancelNotification: true,
//             showsUserInterface: true,
//           ),
//         ],
//       );

//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: false,
//         interruptionLevel: InterruptionLevel.active,
//       );

//       const notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await _notifications.show(
//         1, // Notification ID
//         'Location Service Active',
//         'Tracking your location in the background',
//         notificationDetails,
//         payload: 'location_service',
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error showing service notification: $e');
//       }
//     }
//   }

//   static Future<void> showLocationUpdateNotification(String message) async {
//     try {
//       final androidDetails = AndroidNotificationDetails(
//         _channel.id,
//         _channel.name,
//         channelDescription: _channel.description,
//         importance: Importance.high,
//         priority: Priority.high,
//         styleInformation: InboxStyleInformation(
//           [message],
//           contentTitle: 'Location Update',
//           summaryText: 'Latest location sync',
//         ),
//       );

//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: const DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       );

//       await _notifications.show(
//         2, // Different ID from service notification
//         'Location Update',
//         message,
//         notificationDetails,
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error showing location update notification: $e');
//       }
//     }
//   }

//   static Future<void> cancelServiceNotification() async {
//     await _notifications.cancel(1);
//   }
// }
