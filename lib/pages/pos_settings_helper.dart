import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/utils/configs.dart';

class PosSettingsHelper {
  static Future<void> saveSettings({
    required String url,
    required String stationName,
    required String fetchingTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use the actual constants from configs.dart
    await prefs.setString(urlKey, url);                    // 'tatsUrl'
    await prefs.setString(stationNameKey, stationName);    // 'stationName'  
    await prefs.setString(durationKey, fetchingTime);      // 'duration'
  }

  static Future<Map<String, String>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString(urlKey) ?? '',               // 'tatsUrl'
      'stationName': prefs.getString(stationNameKey) ?? '', // 'stationName'
      'fetchingTime': prefs.getString(durationKey) ?? '',   // 'duration'
    };
  }
}