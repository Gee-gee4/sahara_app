import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeviceValidator {
  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('webApiServiceUrl');

    if (baseUrl == null) return false;

    final deviceId = await _getDeviceId();
    await prefs.setString('deviceId', deviceId); // ✅ save it for future use

    final url = Uri.parse('$baseUrl/device/validate?deviceId=$deviceId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['registered'] == true;
    } else {
      return false;
    }
  }

  static Future<String> _getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id; // Guaranteed non-null in latest versions
}

}
