
import 'package:flutter/services.dart';

class Service{
  static const platform = MethodChannel('com.example.app/background_service');
// To start the service
Future startService() async {
  try{
    await platform.invokeMethod('startLocationService');
    }catch(e){
      print("Error starting service: $e");
    }
}
Future<bool> isRunningService()async{
  try{
  bool isRunning = await platform.invokeMethod('isServiceRunning');
  return isRunning;
  }catch(ex){
    throw Exception(ex);
  }

}

// To stop the service
// await platform.invokeMethod('stopLocationService');
}