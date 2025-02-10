
import 'package:app/app/pages/sign_in_screen.dart';
import 'package:app/core/config/token_storage.dart';
import 'package:app/test.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // _checkServiceStatus();
  }

  Future<void> _initializeServices() async {
    try {
      // final notificationsPlugin = FlutterLocalNotificationsPlugin();
      //  BackgroundHttpService(notificationsPlugin: notificationsPlugin).startBackgroundService();
      // await BackgroundService.initialize();
      // await BackgroundService.startPeriodicTask();
      Service service = Service();
      await service.startService();
      bool isRun = await service.isRunningService();
      if (mounted) {
        setState(() {
          _isServiceRunning = isRun;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
             TokenStorage.clearToken();
             Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Location Service Status',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.location_on ,
              size: 48,
              color: Colors.green ,
            ),
            const SizedBox(height: 20),
            const Text(
              'Service is Running' ,
              style: TextStyle(
                fontSize: 18,
                color:  Colors.green ,
              ),
            ),

            TextButton(
              child:const Text("Get Token"),
              onPressed:()async{
                print("Token : ${await TokenStorage.getToken()}");
              },
            ),
          ],
        ),
      ),
    );
  }
}