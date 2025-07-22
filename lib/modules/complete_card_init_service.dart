import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/models/complete_card_init_model.dart';

class CompleteCardInitService {
  static Future<String?> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webApiServiceUrl');
    if (url == null) return null;
    return '$url/api';
  }

  // This sends the POST request
  static Future<String?> postCompleteInit(CompleteCardInitModel model) async {
    final base = await baseUrl;
    if (base == null) return null;

    final url = Uri.parse('$base/CompleteCardTagInitialize');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );

    if (res.statusCode == 200) {
      return '✅ Card initialization reported successfully';
    } else {
      print('❌ Failed to complete init: ${res.body}');
      return null;
    }
  }
}
