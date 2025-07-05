import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static Future<void> saveResourceModel({
    required String channel,
    required String colorResource,
    required String drawableResource,
    required String webApiServiceUrl,
    required String resourceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('channel', channel);
    await prefs.setString('colorResource', colorResource);
    await prefs.setString('drawableResource', drawableResource);
    await prefs.setString('webApiServiceUrl', webApiServiceUrl);
    await prefs.setString('resourceName', resourceName);
  }

  static Future<void> savePosSettings({
    required String mode,
    required int receiptCount,
    required bool printPolicies,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('operationMode', mode);
    await prefs.setInt('receiptCount', receiptCount);
    await prefs.setBool('printPolicies', printPolicies);
  }
}

Future<String?> apiUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('webApiServiceUrl');
}
