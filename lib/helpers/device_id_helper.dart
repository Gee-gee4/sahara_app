// import 'package:device_info_plus/device_info_plus.dart';
// import 'dart:io';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';

// class DeviceIdHelper {
//   static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

//   // Get Android ID (most likely what your portal expects)
//   static Future<String> getAndroidId() async {
//     try {
//       if (Platform.isAndroid) {
//         AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
//         return androidInfo.id; // This should give you the Android ID
//       }
//       return 'unknown';
//     } catch (e) {
//       print('Error getting Android ID: $e');
//       return 'unknown';
//     }
//   }

//   // Get a consistent device identifier (fallback method)
//   static Future<String> getDeviceId() async {
//     try {
//       if (Platform.isAndroid) {
//         AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        
//         // Try different identifiers in order of preference
//         String deviceId = androidInfo.id; // Android ID
        
//         if (deviceId.isEmpty || deviceId == 'unknown') {
//           // Fallback: create hash from device info
//           String deviceInfoString = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.device}';
//           var bytes = utf8.encode(deviceInfoString);
//           var digest = sha256.convert(bytes);
//           deviceId = digest.toString().substring(0, 16); // First 16 chars
//         }
        
//         return deviceId;
//       }
//       return 'unknown';
//     } catch (e) {
//       print('Error getting device ID: $e');
//       return 'unknown';
//     }
//   }

//   // Get all available device identifiers for debugging
//   static Future<Map<String, String>> getAllDeviceInfo() async {
//     Map<String, String> deviceData = {};
    
//     try {
//       if (Platform.isAndroid) {
//         AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        
//         deviceData['androidId'] = androidInfo.id;
//         deviceData['model'] = androidInfo.model;
//         deviceData['brand'] = androidInfo.brand;
//         deviceData['device'] = androidInfo.device;
//         deviceData['display'] = androidInfo.display;
//         deviceData['fingerprint'] = androidInfo.fingerprint;
//         deviceData['hardware'] = androidInfo.hardware;
//         deviceData['host'] = androidInfo.host;
//         deviceData['manufacturer'] = androidInfo.manufacturer;
//         deviceData['product'] = androidInfo.product;
//         deviceData['serial'] = androidInfo.serialNumber;
        
//         // Create a hash-based ID as backup
//         String deviceInfoString = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.device}';
//         var bytes = utf8.encode(deviceInfoString);
//         var digest = sha256.convert(bytes);
//         deviceData['hashId'] = digest.toString().substring(0, 16);
//       }
//     } catch (e) {
//       print('Error getting device info: $e');
//     }
    
//     return deviceData;
//   }

//   // Test which ID matches your portal's expected format
//   static Future<void> debugDeviceIds() async {
//     print('=== DEVICE ID DEBUG ===');
    
//     Map<String, String> allInfo = await getAllDeviceInfo();
    
//     allInfo.forEach((key, value) {
//       print('$key: $value');
//     });
    
//     print('Expected Portal ID: 044ba7ee5cdd86c5');
//     print('========================');
//   }
// }