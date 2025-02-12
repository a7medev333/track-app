
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
  Service service = Service();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {

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
  void dispose() {
    super.dispose();
    stopService();
  }

  stopService()async{
    await service.stopService();
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
             await stopService();
             // ignore: use_build_context_synchronously
             Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           
            Icon(
              Icons.location_on ,
              size: 48,
              color: Colors.green ,
            ),
            SizedBox(height: 15),
            Text(
              'Service is Running' ,
              style: TextStyle(
                fontSize: 18,
                color:  Colors.green ,
              ),
            ),

           
          ],
        ),
      ),
    );
  }
}