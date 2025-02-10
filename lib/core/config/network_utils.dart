import 'dart:io';

class DeviceConnection {
  static Future<String> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return 'No IP found';
    } catch (e) {
      return 'Error: $e';
    }
  }
}